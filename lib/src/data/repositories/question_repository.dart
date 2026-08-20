import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/subject.dart';
import '../local/app_database.dart';

/// 题目仓储：题库的增删查改（错题本业务的读写入口）
class QuestionRepository {
  QuestionRepository(this._db);

  final AppDatabase _db;

  Future<QuestionRecord?> get(String id) async {
    final rows = await (_db.select(_db.questionRecords)
          ..where((t) => t.id.equals(id)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// 列表：按更新时间倒序；可按科目/关键词过滤
  Future<List<QuestionRecord>> list({
    String? subject,
    String? keyword,
  }) async {
    final query = _db.select(_db.questionRecords)
      ..where((t) => t.contentStatus.equals('saved'))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final rows = await query.get();

    Iterable<QuestionRecord> result = rows;
    if (subject != null && subject.isNotEmpty) {
      result = result.where((r) => r.subject == subject);
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      final k = keyword.trim();
      result = result.where((r) =>
          r.stem.contains(k) ||
          (r.tags).contains(k) ||
          (r.errorCause ?? '').contains(k));
    }
    return result.toList();
  }

  /// 编辑题目（详情页溢出菜单，v13 遗留项）
  Future<void> updateQuestion({
    required String id,
    String? stem,
    String? answer,
    String? errorCause,
    String? subject,
  }) async {
    await (_db.update(_db.questionRecords)..where((t) => t.id.equals(id)))
        .write(QuestionRecordsCompanion(
      stem: stem == null ? const Value.absent() : Value(stem),
      answer: answer == null ? const Value.absent() : Value(answer),
      errorCause: errorCause == null ? const Value.absent() : Value(errorCause),
      subject: subject == null ? const Value.absent() : Value(subject),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> updateMastery(String id, int level) async {
    await (_db.update(_db.questionRecords)..where((t) => t.id.equals(id)))
        .write(QuestionRecordsCompanion(
      masteryLevel: Value(level.clamp(0, 5)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.questionRecords)..where((t) => t.id.equals(id))).go();
    await (_db.delete(_db.reviewCards)..where((t) => t.questionId.equals(id)))
        .go();
    await (_db.delete(_db.questionKnowledgeLinks)
          ..where((t) => t.questionId.equals(id)))
        .go();
  }

  /// 题目关联的知识点名称列表
  Future<List<String>> knowledgePointsOf(String questionId) async {
    final links = await (_db.select(_db.questionKnowledgeLinks)
          ..where((t) => t.questionId.equals(questionId)))
        .get();
    if (links.isEmpty) return const [];
    final ids = links.map((l) => l.knowledgePointId).toList();
    final kps = await (_db.select(_db.knowledgePoints)
          ..where((t) => t.id.isIn(ids)))
        .get();
    return kps.map((k) => k.name).toList();
  }

  /// 题干步骤（JSON 数组反序列化）
  static List<String> decodeSteps(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  /// 学习建议等解析详情
  static Map<String, dynamic> decodeAnalysisDetail(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  static List<String> decodeTags(String raw) {
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }
}

/// 科目选项（UI 过滤器用）
const subjectFilterOptions = [
  null,
  ...Subject.values,
];
