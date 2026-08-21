import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/app_database.dart';
import 'supabase_config.dart';

/// 云同步结果
class SyncResult {
  const SyncResult({
    required this.ok,
    required this.message,
    this.pushed = 0,
    this.pulled = 0,
    this.imagesUploaded = 0,
    this.imagesDownloaded = 0,
  });

  final bool ok;
  final String message;
  final int pushed;
  final int pulled;
  final int imagesUploaded;
  final int imagesDownloaded;
}

/// Supabase 云同步服务：匿名登录 + 全量双向同步 + 图片云端存储。
///
/// 同步策略（个人错题本场景，数据量小，全量对比最可靠）：
/// - 推送：本地全表 upsert（onConflict=id），remote image_path 只存文件名
/// - 拉取：远端全表下载，按 id 对比，新数据覆盖旧数据（updated_at 仲裁）
/// - 图片：推送时补传缺失文件，拉取时补下载缺失文件
class CloudSyncService {
  CloudSyncService(this._db, this._prefs);

  final AppDatabase _db;
  final SharedPreferences _prefs;

  static const _dirtyKey = 'cloud.dirty';

  SupabaseClient get _client => Supabase.instance.client;

  /// 云端脏标记（与 WebDAV 备份的脏标记相互独立）
  bool get isDirty => _prefs.getBool(_dirtyKey) ?? true;
  Future<void> markDirty() => _prefs.setBool(_dirtyKey, true);

  /// 自动同步：有脏数据 + 在线 → 自动登录并静默同步；失败不打扰用户
  Future<void> autoSync() async {
    if (!isDirty) return;
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn.contains(ConnectivityResult.none)) return;
      final result = await syncNow();
      if (result.ok) await _prefs.setBool(_dirtyKey, false);
    } catch (_) {
      // 静默失败，下次再试
    }
  }

  bool get isSignedIn => _client.auth.currentSession != null;
  String? get _uid => _client.auth.currentUser?.id;

  // ==================== 认证（单用户共享账号，全自动） ====================

  /// 确保已登录共享账号：启动/同步前自动调用，用户无感知。
  /// 会话过期时 supabase_flutter 会自动刷新；彻底失效时重新密码登录。
  Future<bool> ensureSignedIn() async {
    try {
      if (isSignedIn) return true;
      await _client.auth.signInWithPassword(
        email: SupabaseConfig.sharedEmail,
        password: SupabaseConfig.sharedPassword,
      );
      return isSignedIn;
    } catch (_) {
      return false;
    }
  }

  // ==================== 删除墓碑（数据完整性） ====================

  static const _tombstoneKey = 'cloud.tombstone.questions';

  /// 记录本地已删除的题目（下次同步时同步删除云端对应数据）
  Future<void> recordQuestionDeleted(String questionId) async {
    final list = _prefs.getStringList(_tombstoneKey) ?? [];
    if (!list.contains(questionId)) {
      list.add(questionId);
      await _prefs.setStringList(_tombstoneKey, list);
    }
    await markDirty();
  }

  Future<void> _applyTombstones(String uid) async {
    final list = _prefs.getStringList(_tombstoneKey) ?? [];
    if (list.isEmpty) return;
    // 云端级联删除：题目 + 复习卡 + 关联 + 日志
    await _client
        .from('question_records')
        .delete()
        .eq('user_id', uid)
        .inFilter('id', list);
    await _client
        .from('review_cards')
        .delete()
        .eq('user_id', uid)
        .inFilter('question_id', list);
    await _client
        .from('question_knowledge_links')
        .delete()
        .eq('user_id', uid)
        .inFilter('question_id', list);
    await _client
        .from('review_logs')
        .delete()
        .eq('user_id', uid)
        .inFilter('question_id', list);
    await _prefs.remove(_tombstoneKey);
  }

  /// 孤儿图片清理：云端题目都不再引用的图片删掉（删除传播的兜底）
  Future<void> _cleanOrphanImages(String uid) async {
    try {
      final remote = await _client
          .from('question_records')
          .select('image_path')
          .eq('user_id', uid);
      final referenced = remote
          .map((r) => (r['image_path'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet();
      final files = await _client.storage
          .from(SupabaseConfig.imagesBucket)
          .list(path: uid);
      final orphans = files
          .map((f) => f.name)
          .where((name) => !referenced.contains(name))
          .toList();
      if (orphans.isNotEmpty) {
        await _client.storage
            .from(SupabaseConfig.imagesBucket)
            .remove([for (final o in orphans) '$uid/$o']);
      }
    } catch (_) {
      // 清理失败不影响同步主流程
    }
  }

  // ==================== 同步 ====================

  /// 全量双向同步（单用户：自动登录 → 墓碑删除 → 推送 → 拉取 → 清理）
  Future<SyncResult> syncNow() async {
    if (!await ensureSignedIn()) {
      return const SyncResult(ok: false, message: '云同步暂不可用：网络异常或未配置');
    }
    final uid = _uid!;
    try {
      var pushed = 0;
      var pulled = 0;

      // 删除传播：本地删过的题目，云端同步删
      await _applyTombstones(uid);

      // 顺序有依赖：先知识点，再题目，再关联/复习数据
      pushed += await _pushKnowledgePoints(uid);
      pulled += await _pullKnowledgePoints(uid);

      final imgStats = await _pushQuestionRecords(uid);
      pushed += imgStats.rows;
      pulled += await _pullQuestionRecords(uid);

      pushed += await _pushLinks(uid);
      pulled += await _pullLinks(uid);

      pushed += await _pushReviewCards(uid);
      pulled += await _pullReviewCards(uid);

      pushed += await _pushReviewLogs(uid);
      pulled += await _pullReviewLogs(uid);

      pushed += await _pushGeneratedExercises(uid);
      pulled += await _pullGeneratedExercises(uid);

      pushed += await _pushQuestionBank(uid);
      pulled += await _pullQuestionBank(uid);

      // 孤儿图片清理（删除兜底）
      await _cleanOrphanImages(uid);

      await _writeSyncState(uid, pushed, pulled);

      return SyncResult(
        ok: true,
        message: '同步完成：上传 $pushed 条，下载 $pulled 条'
            '${imgStats.uploaded > 0 ? '，补传图片 ${imgStats.uploaded} 张' : ''}',
        pushed: pushed,
        pulled: pulled,
        imagesUploaded: imgStats.uploaded,
      );
    } on PostgrestException catch (e) {
      return SyncResult(ok: false, message: '同步失败：${_humanize(e.message)}');
    } on StorageException catch (e) {
      return SyncResult(ok: false, message: '图片同步失败：${_humanize(e.message)}');
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        return const SyncResult(ok: false, message: '同步失败：网络异常，请检查网络后重试');
      }
      return SyncResult(ok: false, message: '同步失败：${_humanize(e.toString())}');
    }
  }

  // ==================== question_records ====================

  Future<({int rows, int uploaded})> _pushQuestionRecords(String uid) async {
    final rows = await _db.select(_db.questionRecords).get();
    if (rows.isEmpty) return (rows: 0, uploaded: 0);

    // 远端已有图片清单（避免重复上传）
    final remoteImages = await _listRemoteImages(uid);
    var uploaded = 0;

    final payload = <Map<String, dynamic>>[];
    for (final q in rows) {
      String? remoteImage;
      if (q.imagePath != null && q.imagePath!.isNotEmpty) {
        final name = p.basename(q.imagePath!);
        remoteImage = name;
        if (!remoteImages.contains(name)) {
          final f = File(q.imagePath!);
          if (f.existsSync()) {
            await _client.storage
                .from(SupabaseConfig.imagesBucket)
                .uploadBinary(
                  '$uid/$name',
                  await f.readAsBytes(),
                  fileOptions: const FileOptions(contentType: 'image/jpeg'),
                );
            uploaded++;
          }
        }
      }
      payload.add({
        'user_id': uid,
        'id': q.id,
        'subject': q.subject,
        'image_path': remoteImage,
        'stem': q.stem,
        'answer': q.answer,
        'key_steps': q.keySteps,
        'error_cause': q.errorCause,
        'analysis_detail': q.analysisDetail,
        'tags': q.tags,
        'source': q.source,
        'content_status': q.contentStatus,
        'mastery_level': q.masteryLevel,
        'created_at': q.createdAt.toUtc().toIso8601String(),
        'updated_at': q.updatedAt.toUtc().toIso8601String(),
      });
    }
    for (var i = 0; i < payload.length; i += 200) {
      final chunk = payload.sublist(
          i, i + 200 > payload.length ? payload.length : i + 200);
      await _client.from('question_records').upsert(chunk, onConflict: 'id');
    }
    return (rows: rows.length, uploaded: uploaded);
  }

  Future<int> _pullQuestionRecords(String uid) async {
    final remote =
        await _client.from('question_records').select().eq('user_id', uid);
    if (remote.isEmpty) return 0;

    final localRows = await _db.select(_db.questionRecords).get();
    final localById = {for (final q in localRows) q.id: q};
    final capturesDir = await _capturesDir();
    var pulled = 0;

    for (final r in remote) {
      final id = (r['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final remoteUpdated = _parseTime(r['updated_at']);
      final local = localById[id];

      // 本地更新 → 跳过（本地数据会在下次 push 上去）
      if (local != null &&
          remoteUpdated != null &&
          local.updatedAt.isAfter(remoteUpdated)) {
        continue;
      }

      // 图片补下载
      String? localImagePath;
      final remoteImage = (r['image_path'] ?? '').toString();
      if (remoteImage.isNotEmpty) {
        final localFile = File(p.join(capturesDir.path, remoteImage));
        if (!localFile.existsSync()) {
          try {
            final bytes = await _client.storage
                .from(SupabaseConfig.imagesBucket)
                .download('$uid/$remoteImage');
            await localFile.writeAsBytes(bytes);
          } catch (_) {
            // 图片缺失不阻塞题目同步
          }
        }
        if (localFile.existsSync()) localImagePath = localFile.path;
      }

      await _db.into(_db.questionRecords).insert(
            QuestionRecordsCompanion.insert(
              id: id,
              subject: Value((r['subject'] ?? '').toString()),
              imagePath: Value(localImagePath),
              stem: Value((r['stem'] ?? '').toString()),
              answer: Value(r['answer']?.toString()),
              keySteps: Value(r['key_steps']?.toString()),
              errorCause: Value(r['error_cause']?.toString()),
              analysisDetail: Value(r['analysis_detail']?.toString()),
              tags: Value((r['tags'] ?? '').toString()),
              source: Value((r['source'] ?? '').toString()),
              contentStatus: Value((r['content_status'] ?? 'saved').toString()),
              masteryLevel: Value((r['mastery_level'] as num?)?.toInt() ?? 0),
              createdAt: _parseTime(r['created_at']) ?? DateTime.now(),
              updatedAt: remoteUpdated ?? DateTime.now(),
            ),
            mode: InsertMode.insertOrReplace,
          );
      pulled++;
    }
    return pulled;
  }

  // ==================== knowledge_points ====================

  Future<int> _pushKnowledgePoints(String uid) async {
    final rows = await _db.select(_db.knowledgePoints).get();
    if (rows.isEmpty) return 0;
    final payload = [
      for (final k in rows)
        {
          'user_id': uid,
          'id': k.id,
          'subject': k.subject,
          'version': k.version,
          'book': k.book,
          'chapter': k.chapter,
          'lesson': k.lesson,
          'name': k.name,
          'first_seen_at': k.firstSeenAt.toUtc().toIso8601String(),
          'updated_at': k.firstSeenAt.toUtc().toIso8601String(),
        }
    ];
    for (var i = 0; i < payload.length; i += 200) {
      await _client.from('knowledge_points').upsert(
          payload.sublist(
              i, i + 200 > payload.length ? payload.length : i + 200),
          onConflict: 'id');
    }
    return rows.length;
  }

  Future<int> _pullKnowledgePoints(String uid) async {
    final remote =
        await _client.from('knowledge_points').select().eq('user_id', uid);
    if (remote.isEmpty) return 0;
    final localRows = await _db.select(_db.knowledgePoints).get();
    final localById = {for (final k in localRows) k.id: k};
    var pulled = 0;
    for (final r in remote) {
      final id = (r['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final remoteUpdated = _parseTime(r['updated_at']);
      final local = localById[id];
      if (local != null &&
          remoteUpdated != null &&
          local.firstSeenAt.isAfter(remoteUpdated)) {
        continue;
      }
      await _db.into(_db.knowledgePoints).insert(
            KnowledgePointsCompanion.insert(
              id: id,
              subject: Value((r['subject'] ?? '').toString()),
              version: Value((r['version'] ?? '').toString()),
              book: Value((r['book'] ?? '').toString()),
              chapter: Value((r['chapter'] ?? '').toString()),
              lesson: Value((r['lesson'] ?? '').toString()),
              name: (r['name'] ?? '').toString(),
              firstSeenAt: _parseTime(r['first_seen_at']) ?? DateTime.now(),
            ),
            mode: InsertMode.insertOrReplace,
          );
      pulled++;
    }
    return pulled;
  }

  // ==================== question_knowledge_links ====================

  Future<int> _pushLinks(String uid) async {
    final rows = await _db.select(_db.questionKnowledgeLinks).get();
    if (rows.isEmpty) return 0;
    final payload = [
      for (final l in rows)
        {
          'user_id': uid,
          'id': l.id,
          'question_id': l.questionId,
          'knowledge_point_id': l.knowledgePointId,
        }
    ];
    for (var i = 0; i < payload.length; i += 200) {
      await _client.from('question_knowledge_links').upsert(
          payload.sublist(
              i, i + 200 > payload.length ? payload.length : i + 200),
          onConflict: 'id');
    }
    return rows.length;
  }

  Future<int> _pullLinks(String uid) async {
    final remote = await _client
        .from('question_knowledge_links')
        .select()
        .eq('user_id', uid);
    if (remote.isEmpty) return 0;
    final localPairs = (await _db.select(_db.questionKnowledgeLinks).get())
        .map((l) => '${l.questionId}|${l.knowledgePointId}')
        .toSet();
    var pulled = 0;
    for (final r in remote) {
      final qid = (r['question_id'] ?? '').toString();
      final kpid = (r['knowledge_point_id'] ?? '').toString();
      if (qid.isEmpty || kpid.isEmpty) continue;
      if (localPairs.contains('$qid|$kpid')) continue;
      await _db.into(_db.questionKnowledgeLinks).insert(
            QuestionKnowledgeLinksCompanion.insert(
              questionId: qid,
              knowledgePointId: kpid,
            ),
          );
      pulled++;
    }
    return pulled;
  }

  // ==================== review_cards ====================

  Future<int> _pushReviewCards(String uid) async {
    final rows = await _db.select(_db.reviewCards).get();
    if (rows.isEmpty) return 0;
    final payload = [
      for (final c in rows)
        {
          'user_id': uid,
          'id': c.id,
          'question_id': c.questionId,
          'due': c.due.toUtc().toIso8601String(),
          'state': c.state,
          'step': c.step,
          'stability': c.stability,
          'difficulty': c.difficulty,
          'easiness_factor': c.easinessFactor,
          'interval_days': c.intervalDays,
          'reps': c.reps,
          'lapses': c.lapses,
          'last_review_at': c.lastReviewAt?.toUtc().toIso8601String(),
          'created_at': c.createdAt.toUtc().toIso8601String(),
          'updated_at':
              (c.lastReviewAt ?? c.createdAt).toUtc().toIso8601String(),
        }
    ];
    for (var i = 0; i < payload.length; i += 200) {
      await _client.from('review_cards').upsert(
          payload.sublist(
              i, i + 200 > payload.length ? payload.length : i + 200),
          onConflict: 'id');
    }
    return rows.length;
  }

  Future<int> _pullReviewCards(String uid) async {
    final remote =
        await _client.from('review_cards').select().eq('user_id', uid);
    if (remote.isEmpty) return 0;
    final localRows = await _db.select(_db.reviewCards).get();
    final localById = {for (final c in localRows) c.id: c};
    var pulled = 0;
    for (final r in remote) {
      final id = (r['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final remoteFresh = _parseTime(r['updated_at']);
      final local = localById[id];
      if (local != null && remoteFresh != null) {
        final localFresh = local.lastReviewAt ?? local.createdAt;
        if (localFresh.isAfter(remoteFresh)) continue;
      }
      await _db.into(_db.reviewCards).insert(
            ReviewCardsCompanion.insert(
              id: id,
              questionId: (r['question_id'] ?? '').toString(),
              due: _parseTime(r['due']) ?? DateTime.now(),
              state: Value((r['state'] as num?)?.toInt() ?? 0),
              step: Value((r['step'] as num?)?.toInt()),
              stability: Value(((r['stability'] as num?) ?? 0).toDouble()),
              difficulty: Value(((r['difficulty'] as num?) ?? 0).toDouble()),
              easinessFactor:
                  Value(((r['easiness_factor'] as num?) ?? 2.5).toDouble()),
              intervalDays: Value((r['interval_days'] as num?)?.toInt() ?? 0),
              reps: Value((r['reps'] as num?)?.toInt() ?? 0),
              lapses: Value((r['lapses'] as num?)?.toInt() ?? 0),
              lastReviewAt: Value(_parseTime(r['last_review_at'])),
              createdAt: _parseTime(r['created_at']) ?? DateTime.now(),
            ),
            mode: InsertMode.insertOrReplace,
          );
      pulled++;
    }
    return pulled;
  }

  // ==================== review_logs ====================

  Future<int> _pushReviewLogs(String uid) async {
    final rows = await _db.select(_db.reviewLogs).get();
    if (rows.isEmpty) return 0;
    final payload = [
      for (final l in rows)
        {
          'user_id': uid,
          'id': l.id,
          'question_id': l.questionId,
          'rating': l.rating,
          'reviewed_at': l.reviewedAt.toUtc().toIso8601String(),
          'duration_ms': l.durationMs,
        }
    ];
    for (var i = 0; i < payload.length; i += 200) {
      await _client.from('review_logs').upsert(
          payload.sublist(
              i, i + 200 > payload.length ? payload.length : i + 200),
          onConflict: 'id');
    }
    return rows.length;
  }

  Future<int> _pullReviewLogs(String uid) async {
    final remote =
        await _client.from('review_logs').select().eq('user_id', uid);
    if (remote.isEmpty) return 0;
    final localKeys = (await _db.select(_db.reviewLogs).get())
        .map((l) =>
            '${l.questionId}|${l.reviewedAt.millisecondsSinceEpoch}|${l.rating}')
        .toSet();
    var pulled = 0;
    for (final r in remote) {
      final qid = (r['question_id'] ?? '').toString();
      final reviewedAt = _parseTime(r['reviewed_at']);
      final rating = (r['rating'] as num?)?.toInt() ?? 3;
      if (qid.isEmpty || reviewedAt == null) continue;
      if (localKeys
          .contains('$qid|${reviewedAt.millisecondsSinceEpoch}|$rating')) {
        continue;
      }
      await _db.into(_db.reviewLogs).insert(
            ReviewLogsCompanion.insert(
              questionId: qid,
              rating: rating,
              reviewedAt: reviewedAt,
              durationMs: Value((r['duration_ms'] as num?)?.toInt()),
            ),
          );
      pulled++;
    }
    return pulled;
  }

  // ==================== generated_exercises ====================

  Future<int> _pushGeneratedExercises(String uid) async {
    final rows = await _db.select(_db.generatedExercises).get();
    if (rows.isEmpty) return 0;
    final payload = [
      for (final g in rows)
        {
          'user_id': uid,
          'id': g.id,
          'question_id': g.questionId,
          'content': g.content,
          'status': g.status,
          'created_at': g.createdAt.toUtc().toIso8601String(),
          'completed_at': g.completedAt?.toUtc().toIso8601String(),
          'updated_at':
              (g.completedAt ?? g.createdAt).toUtc().toIso8601String(),
        }
    ];
    for (var i = 0; i < payload.length; i += 200) {
      await _client.from('generated_exercises').upsert(
          payload.sublist(
              i, i + 200 > payload.length ? payload.length : i + 200),
          onConflict: 'id');
    }
    return rows.length;
  }

  Future<int> _pullGeneratedExercises(String uid) async {
    final remote =
        await _client.from('generated_exercises').select().eq('user_id', uid);
    if (remote.isEmpty) return 0;
    final localRows = await _db.select(_db.generatedExercises).get();
    final localById = {for (final g in localRows) g.id: g};
    var pulled = 0;
    for (final r in remote) {
      final id = (r['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final local = localById[id];
      if (local != null) continue; // 本地已有不覆盖（内容只增不改）
      await _db.into(_db.generatedExercises).insert(
            GeneratedExercisesCompanion.insert(
              id: id,
              questionId: (r['question_id'] ?? '').toString(),
              content: (r['content'] ?? '').toString(),
              status: Value((r['status'] ?? 'pending').toString()),
              createdAt: _parseTime(r['created_at']) ?? DateTime.now(),
              completedAt: Value(_parseTime(r['completed_at'])),
            ),
          );
      pulled++;
    }
    return pulled;
  }

  // ==================== question_bank ====================

  Future<int> _pushQuestionBank(String uid) async {
    final rows = await _db.select(_db.questionBank).get();
    if (rows.isEmpty) return 0;
    final payload = [
      for (final b in rows)
        {
          'user_id': uid,
          'id': b.id,
          'source_question_id': b.sourceQuestionId,
          'knowledge_point_id': b.knowledgePointId,
          'subject': b.subject,
          'question_type': b.questionType,
          'difficulty': b.difficulty,
          'content': b.content,
          'kind': b.kind,
          'source_label': b.sourceLabel,
          'source_citation': b.sourceCitation,
          'used_count': b.usedCount,
          'created_at': b.createdAt.toUtc().toIso8601String(),
          'updated_at': b.createdAt.toUtc().toIso8601String(),
        }
    ];
    for (var i = 0; i < payload.length; i += 200) {
      await _client.from('question_bank').upsert(
          payload.sublist(
              i, i + 200 > payload.length ? payload.length : i + 200),
          onConflict: 'id');
    }
    return rows.length;
  }

  Future<int> _pullQuestionBank(String uid) async {
    final remote =
        await _client.from('question_bank').select().eq('user_id', uid);
    if (remote.isEmpty) return 0;
    final localRows = await _db.select(_db.questionBank).get();
    final localById = {for (final b in localRows) b.id: b};
    var pulled = 0;
    for (final r in remote) {
      final id = (r['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final local = localById[id];
      if (local != null) {
        // used_count 取大值（两端都可能消耗过）
        final remoteUsed = (r['used_count'] as num?)?.toInt() ?? 0;
        if (remoteUsed > local.usedCount) {
          await (_db.update(_db.questionBank)..where((t) => t.id.equals(id)))
              .write(QuestionBankCompanion(usedCount: Value(remoteUsed)));
        }
        continue;
      }
      await _db.into(_db.questionBank).insert(
            QuestionBankCompanion.insert(
              id: id,
              sourceQuestionId: Value(r['source_question_id']?.toString()),
              knowledgePointId: Value(r['knowledge_point_id']?.toString()),
              subject: Value((r['subject'] ?? '').toString()),
              questionType: Value((r['question_type'] ?? 'solve').toString()),
              difficulty: Value((r['difficulty'] ?? 'medium').toString()),
              content: (r['content'] ?? '').toString(),
              kind: (r['kind'] ?? 'real_exam').toString(),
              sourceLabel: (r['source_label'] ?? '').toString(),
              sourceCitation: Value(r['source_citation']?.toString()),
              usedCount: Value((r['used_count'] as num?)?.toInt() ?? 0),
              createdAt: _parseTime(r['created_at']) ?? DateTime.now(),
            ),
          );
      pulled++;
    }
    return pulled;
  }

  // ==================== 工具 ====================

  Future<Set<String>> _listRemoteImages(String uid) async {
    try {
      final files = await _client.storage
          .from(SupabaseConfig.imagesBucket)
          .list(path: uid);
      return files.map((f) => f.name).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<Directory> _capturesDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, 'captures'))..createSync(recursive: true);
  }

  Future<void> _writeSyncState(String uid, int pushed, int pulled) async {
    try {
      await _client.from('sync_state').upsert({
        'user_id': uid,
        'table_name': '_all',
        'last_sync_at': DateTime.now().toUtc().toIso8601String(),
        'rows_pushed': pushed,
        'rows_pulled': pulled,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,table_name');
    } catch (_) {
      // 状态记录失败不影响同步本身
    }
  }

  DateTime? _parseTime(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  /// 错误信息人话化（不泄露堆栈/英文原文给最终用户之外的场景保持可读）
  String _humanize(String msg) {
    if (msg.contains('Invalid login credentials')) return '邮箱或密码不正确';
    if (msg.contains('already registered')) return '该邮箱已注册，请直接登录';
    if (msg.contains('rate limit')) return '操作太频繁，请稍后再试';
    if (msg.contains('network') || msg.contains('SocketException')) {
      return '网络异常，请检查网络后重试';
    }
    return msg;
  }
}
