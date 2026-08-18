import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/ai/analysis_gateway.dart';
import '../../domain/models/analysis_result.dart';
import '../local/app_database.dart';

const _uuid = Uuid();

/// AI 网关解析器：运行时按需取网关（未配置时返回 null）
typedef AiGatewayResolver = Future<AiAnalysisGateway?> Function();

/// 解析管线 —— 拍题 → 拆题 → 逐题解析 → 保存 的状态机与串行队列。
///
/// 移植自 awn 的任务队列设计并强化：
/// - 严格串行：同一时刻只有一个 AI 请求，杜绝并发消耗
/// - 状态落库：每一步都持久化，重启后可恢复
/// - 单题重试：多题中某题失败，只重试该题
/// - 部分成功：保存时只入库成功题
class AnalysisPipeline extends ChangeNotifier {
  AnalysisPipeline({
    required AppDatabase db,
    required AiGatewayResolver gatewayResolver,
    ImageBytesLoader? imageLoader,
  })  : _db = db,
        _gatewayResolver = gatewayResolver,
        _imageLoader = imageLoader ?? defaultImageBytesLoader;

  final AppDatabase _db;
  final AiGatewayResolver _gatewayResolver;
  final ImageBytesLoader _imageLoader;

  /// 串行队列尾指针：所有 AI 操作都挂在链上排队
  Future<void> _queueTail = Future.value();

  /// 提交拍题任务，返回 job id。立即返回，解析在后台排队进行。
  Future<String> submit(String imagePath) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.analysisJobs).insert(
          AnalysisJobsCompanion.insert(
            id: id,
            imagePath: imagePath,
            status: const Value('pending'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    _enqueue(() => _processJob(id));
    notifyListeners();
    return id;
  }

  /// 重试任务中的单个失败题
  void retryCandidate(String jobId, int index) {
    _enqueue(() => _retryOne(jobId, index));
  }

  /// 重试整个失败任务（拆题失败等）
  void retryJob(String jobId) {
    _enqueue(() => _processJob(jobId));
  }

  /// 保存任务中的成功题（入库 + 建复习卡 + 写学习事件），返回入库题目 id
  Future<List<String>> saveJob(String jobId) async {
    final job = await _getJob(jobId);
    if (job == null) return const [];

    final candidates = _decodeResults(job.results);
    final savedIds = <String>[];
    final now = DateTime.now();

    for (final c in candidates) {
      if (c.status != CandidateStatus.success || c.result == null) continue;
      final r = c.result!;
      final qid = _uuid.v4();

      await _db.into(_db.questionRecords).insert(
            QuestionRecordsCompanion.insert(
              id: qid,
              subject: Value(r.subject.label),
              imagePath: Value(job.imagePath),
              stem: Value(r.stem),
              answer: Value(r.finalAnswer),
              keySteps: Value(jsonEncode(r.steps)),
              errorCause: Value(r.mistakeReason),
              analysisDetail: Value(jsonEncode({
                'studyAdvice': r.studyAdvice,
                'knowledgePoints': r.knowledgePoints,
              })),
              tags: Value(jsonEncode(r.tags)),
              contentStatus: const Value('saved'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 知识点沉淀 + 关联
      for (final kp in r.knowledgePoints) {
        await _ensureKnowledgePoint(qid, r.subject.label, kp, now);
      }

      // FSRS 复习卡（新卡，due 即刻 → 今天就能开始第一次复习）
      await _db.into(_db.reviewCards).insert(
            ReviewCardsCompanion.insert(
              id: _uuid.v4(),
              questionId: qid,
              due: now,
              createdAt: now,
            ),
          );

      // 学习事件流 → 成长引擎
      await _db.into(_db.learningEvents).insert(
            LearningEventsCompanion.insert(
              eventType: 'analysis_done',
              questionId: Value(qid),
              at: now,
              payload: Value(jsonEncode({
                'subject': r.subject.name,
                'tags': r.tags,
              })),
            ),
          );

      savedIds.add(qid);
    }

    await _updateJob(jobId, status: 'saved');
    notifyListeners();
    return savedIds;
  }

  /// 放弃任务（未保存的结果直接丢弃）
  Future<void> abandonJob(String jobId) async {
    await _updateJob(jobId, status: 'abandoned');
    notifyListeners();
  }

  /// 启动时恢复：把中断在 splitting/analyzing/pending 的任务重新排队
  Future<void> resumeInterrupted() async {
    final rows = await (_db.select(_db.analysisJobs)
          ..where((t) => t.status.isIn([
                'pending',
                'splitting',
                'analyzing',
              ])))
        .get();
    for (final row in rows) {
      _enqueue(() => _processJob(row.id));
    }
  }

  // ---------- 内部 ----------

  void _enqueue(Future<void> Function() task) {
    _queueTail = _queueTail.then((_) => task()).catchError((Object e) {
      debugPrint('AnalysisPipeline 任务异常：$e');
    });
  }

  Future<AnalysisJob?> _getJob(String id) async {
    final rows = await (_db.select(_db.analysisJobs)
          ..where((t) => t.id.equals(id)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> _processJob(String jobId) async {
    final job = await _getJob(jobId);
    if (job == null) return;

    final gateway = await _gatewayResolver();
    if (gateway == null) {
      await _updateJob(jobId, status: 'failed', error: '请先在设置中配置 AI 服务商');
      notifyListeners();
      return;
    }

    List<int> imageBytes;
    try {
      imageBytes = await _imageLoader(job.imagePath);
    } catch (e) {
      await _updateJob(jobId, status: 'failed', error: '图片读取失败：$e');
      notifyListeners();
      return;
    }

    // 1) 拆题
    await _updateJob(jobId, status: 'splitting');
    List<QuestionCandidate> candidates;
    try {
      candidates = await gateway.splitQuestions(imageBytes: imageBytes);
    } catch (e) {
      // 拆题失败降级为单题直解（整图作为一道题）
      candidates = const [QuestionCandidate(index: 1, text: '')];
    }
    await _updateJob(
      jobId,
      splitResult: jsonEncode(candidates.map((c) => c.toJson()).toList()),
    );

    // 2) 逐题解析
    await _updateJob(
      jobId,
      status: 'analyzing',
      results: jsonEncode(candidates
          .map((c) =>
              CandidateAnalysis(index: c.index, status: CandidateStatus.pending)
                  .toJson())
          .toList()),
    );

    var results = _decodeResults((await _getJob(jobId))!.results);
    for (var i = 0; i < candidates.length; i++) {
      results = await _analyzeCandidate(
        jobId,
        results,
        i,
        candidates[i],
        imageBytes,
        gateway,
      );
    }

    final anySuccess = results.any((c) => c.status == CandidateStatus.success);
    await _updateJob(
      jobId,
      status: anySuccess ? 'waiting_confirm' : 'failed',
      error: anySuccess ? null : '所有题目解析失败',
    );
    notifyListeners();
  }

  Future<List<CandidateAnalysis>> _analyzeCandidate(
    String jobId,
    List<CandidateAnalysis> results,
    int position,
    QuestionCandidate candidate,
    List<int> imageBytes,
    AiAnalysisGateway gateway,
  ) async {
    results = _setStatus(results, position, CandidateStatus.analyzing);
    await _updateJob(jobId,
        results: jsonEncode(results.map((c) => c.toJson()).toList()));

    try {
      final hasText = candidate.text.trim().isNotEmpty;
      final result = await gateway.analyzeQuestion(
        imageBytes: hasText ? null : imageBytes,
        questionText: hasText ? candidate.text : null,
      );
      results = results
          .map((c) => c.index == candidate.index
              ? c.copyWith(status: CandidateStatus.success, result: result)
              : c)
          .toList();
    } catch (e) {
      results = results
          .map((c) => c.index == candidate.index
              ? c.copyWith(
                  status: CandidateStatus.failed,
                  error: e.toString(),
                )
              : c)
          .toList();
    }
    await _updateJob(jobId,
        results: jsonEncode(results.map((c) => c.toJson()).toList()));
    notifyListeners();
    return results;
  }

  Future<void> _retryOne(String jobId, int index) async {
    final job = await _getJob(jobId);
    if (job == null) return;

    final gateway = await _gatewayResolver();
    if (gateway == null) {
      await _updateJob(jobId, status: 'failed', error: '请先在设置中配置 AI 服务商');
      notifyListeners();
      return;
    }

    final splits = (jsonDecode(job.splitResult) as List)
        .map((e) => QuestionCandidate.fromJson(e as Map<String, dynamic>))
        .toList();
    final candidate = splits.where((c) => c.index == index).firstOrNull;
    if (candidate == null) return;

    final imageBytes = await _imageLoader(job.imagePath);
    await _updateJob(jobId, status: 'analyzing');
    final results = await _analyzeCandidate(
      jobId,
      _decodeResults(job.results),
      splits.indexOf(candidate),
      candidate,
      imageBytes,
      gateway,
    );
    final anySuccess = results.any((c) => c.status == CandidateStatus.success);
    final anyPending = results.any((c) =>
        c.status == CandidateStatus.pending ||
        c.status == CandidateStatus.analyzing);
    await _updateJob(
      jobId,
      status: anyPending
          ? 'analyzing'
          : anySuccess
              ? 'waiting_confirm'
              : 'failed',
    );
    notifyListeners();
  }

  List<CandidateAnalysis> _decodeResults(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CandidateAnalysis.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<CandidateAnalysis> _setStatus(
    List<CandidateAnalysis> results,
    int position,
    CandidateStatus status,
  ) {
    if (position < 0 || position >= results.length) return results;
    final target = results[position];
    return results
        .map((c) => c.index == target.index ? c.copyWith(status: status) : c)
        .toList();
  }

  Future<void> _updateJob(
    String jobId, {
    String? status,
    String? splitResult,
    String? results,
    String? error,
    bool clearError = false,
  }) {
    return (_db.update(_db.analysisJobs)..where((t) => t.id.equals(jobId)))
        .write(AnalysisJobsCompanion(
      status: status == null ? const Value.absent() : Value(status),
      splitResult:
          splitResult == null ? const Value.absent() : Value(splitResult),
      results: results == null ? const Value.absent() : Value(results),
      error: clearError
          ? const Value(null)
          : error == null
              ? const Value.absent()
              : Value(error),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _ensureKnowledgePoint(
    String questionId,
    String subject,
    String name,
    DateTime now,
  ) async {
    final existing = await (_db.select(_db.knowledgePoints)
          ..where((t) => t.subject.equals(subject) & t.name.equals(name)))
        .get();

    final kpId = existing.isEmpty ? _uuid.v4() : existing.first.id;
    if (existing.isEmpty) {
      await _db.into(_db.knowledgePoints).insert(
            KnowledgePointsCompanion.insert(
              id: kpId,
              name: name,
              subject: Value(subject),
              firstSeenAt: now,
            ),
          );
    }

    final linked = await (_db.select(_db.questionKnowledgeLinks)
          ..where((t) =>
              t.questionId.equals(questionId) &
              t.knowledgePointId.equals(kpId)))
        .get();
    if (linked.isEmpty) {
      await _db.into(_db.questionKnowledgeLinks).insert(
            QuestionKnowledgeLinksCompanion.insert(
              questionId: questionId,
              knowledgePointId: kpId,
            ),
          );
    }
  }
}
