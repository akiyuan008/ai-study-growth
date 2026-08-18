import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/generated_exercise.dart';
import '../local/app_database.dart';

const _uuid = Uuid();

/// 举一反三练习仓储
class ExerciseRepository {
  ExerciseRepository(this._db);

  final AppDatabase _db;

  /// 保存一轮生成的练习，返回练习组 id
  Future<String> createForQuestion(
    String questionId,
    List<ExerciseItem> items,
  ) async {
    final id = _uuid.v4();
    await _db.into(_db.generatedExercises).insert(
          GeneratedExercisesCompanion.insert(
            id: id,
            questionId: questionId,
            content: jsonEncode(items.map((i) => i.toJson()).toList()),
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  Future<List<GeneratedExercise>> listForQuestion(String questionId) async {
    return (_db.select(_db.generatedExercises)
          ..where((t) => t.questionId.equals(questionId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  static List<ExerciseItem> decodeItems(String content) {
    try {
      return (jsonDecode(content) as List)
          .map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> markCompleted(String id) async {
    await (_db.update(_db.generatedExercises)..where((t) => t.id.equals(id)))
        .write(GeneratedExercisesCompanion(
      status: const Value('completed'),
      completedAt: Value(DateTime.now()),
    ));
    // 学习事件：练习完成 → 成长引擎
  }
}
