import 'dart:convert';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:uuid/uuid.dart';

import '../../domain/models/generated_exercise.dart';
import '../local/app_database.dart';

const _uuid = Uuid();

/// 题库飞轮仓储（Part 3.5）：
/// 拍题入库（用户真题）→ 举一反三优先 L1 同知识点检索（未用优先）→ 用题回写
class QuestionBankRepository {
  QuestionBankRepository(this._db);

  final AppDatabase _db;

  /// 用户错题入库（拍题保存时调用）：题干作为个人真题
  Future<String> ingestUserQuestion({
    required String questionId,
    required String stem,
    String? knowledgePointId,
    String subject = '',
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.questionBank).insert(
          QuestionBankCompanion.insert(
            id: id,
            sourceQuestionId: Value(questionId),
            knowledgePointId: Value(knowledgePointId),
            subject: Value(subject),
            content: jsonEncode({
              'question': stem,
              'options': const <String>[],
              'answer': '',
              'explanation': '',
            }),
            kind: 'real_exam',
            sourceLabel: '真题 · 来自你的题库',
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  /// AI 生成/引用的练习题入库
  Future<void> ingestExercise({
    required ExerciseItem item,
    String? knowledgePointId,
    String subject = '',
  }) async {
    final kind = switch (item.sourceLevel) {
      ExerciseSourceLevel.l2Cited => 'ai_cited',
      _ => 'ai_generated',
    };
    await _db.into(_db.questionBank).insert(
          QuestionBankCompanion.insert(
            id: _uuid.v4(),
            knowledgePointId: Value(knowledgePointId),
            subject: Value(subject),
            difficulty: Value(_mapDifficulty(item.difficulty)),
            content: jsonEncode(item.toJson()),
            kind: kind,
            sourceLabel: item.displaySourceLabel,
            sourceCitation: Value(
              item.sourceLevel == ExerciseSourceLevel.l2Cited
                  ? item.displaySourceLabel
                  : null,
            ),
            createdAt: DateTime.now(),
          ),
        );
  }

  static String _mapDifficulty(String raw) {
    if (raw.contains('简')) return 'easy';
    if (raw.contains('难') || raw.contains('提高')) return 'hard';
    return 'medium';
  }

  /// L1：同知识点检索，优先未用真题
  Future<List<ExerciseItem>> searchL1({
    required String knowledgePointId,
    int limit = 3,
  }) async {
    final rows = await (_db.select(_db.questionBank)
          ..where((t) =>
              t.knowledgePointId.equals(knowledgePointId) &
              t.kind.equals('real_exam'))
          ..orderBy([
            (t) => OrderingTerm.asc(t.usedCount),
            (t) => OrderingTerm.desc(t.createdAt),
          ])
          ..limit(limit))
        .get();

    return rows.map((row) {
      final content = _decode(row.content);
      return ExerciseItem(
        difficulty: '真题',
        question: (content['question'] ?? '').toString(),
        options: (content['options'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        answer: (content['answer'] ?? '').toString(),
        explanation: (content['explanation'] ?? '').toString(),
        sourceLevel: ExerciseSourceLevel.l1Personal,
        sourceLabel: '真题 · 来自你的题库',
        bankId: row.id,
      );
    }).toList();
  }

  /// 标记已使用（多轮练习每轮优先未用真题）
  Future<void> markUsed(List<String> bankIds) async {
    for (final id in bankIds) {
      final rows = await (_db.select(_db.questionBank)
            ..where((t) => t.id.equals(id)))
          .get();
      if (rows.isEmpty) continue;
      await (_db.update(_db.questionBank)..where((t) => t.id.equals(id)))
          .write(QuestionBankCompanion(
        usedCount: Value(rows.first.usedCount + 1),
      ));
    }
  }

  Map<String, dynamic> _decode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }
}
