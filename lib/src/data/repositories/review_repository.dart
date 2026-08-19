import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart';

import '../local/app_database.dart';
import '../services/review_scheduler.dart';

/// 到期复习卡 + 关联题目
class DueReviewItem {
  const DueReviewItem({required this.card, required this.question});

  final ReviewCard card;
  final QuestionRecord question;
}

/// 复习仓储：FSRS 卡片调度 + 复习日志 + 掌握度联动 + 学习事件
class ReviewRepository {
  ReviewRepository(this._db, {ReviewScheduler? scheduler})
      : _scheduler = scheduler ?? ReviewScheduler();

  final AppDatabase _db;
  final ReviewScheduler _scheduler;

  /// 当前到期的复习卡（按到期时间升序）
  Future<List<DueReviewItem>> dueItems({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final cards = await (_db.select(_db.reviewCards)
          ..where((t) => t.due.isSmallerOrEqualValue(at))
          ..orderBy([(t) => OrderingTerm.asc(t.due)]))
        .get();
    if (cards.isEmpty) return const [];

    final ids = cards.map((c) => c.questionId).toList();
    final questions = await (_db.select(_db.questionRecords)
          ..where((t) => t.id.isIn(ids)))
        .get();
    final byId = {for (final q in questions) q.id: q};

    return cards
        .where((c) => byId.containsKey(c.questionId))
        .map((c) => DueReviewItem(card: c, question: byId[c.questionId]!))
        .toList();
  }

  Future<int> dueCount({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final cards = await (_db.select(_db.reviewCards)
          ..where((t) => t.due.isSmallerOrEqualValue(at)))
        .get();
    return cards.length;
  }

  /// 评分：跑 FSRS → 回写卡片 → 写日志 → 更新掌握度 → 发学习事件
  Future<void> rate({
    required String cardId,
    required Rating rating,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final rows = await (_db.select(_db.reviewCards)
          ..where((t) => t.id.equals(cardId)))
        .get();
    if (rows.isEmpty) return;
    final row = rows.first;

    final card = _scheduler.cardFromStorage(
      cardId: row.createdAt.millisecondsSinceEpoch,
      state: row.state,
      step: row.step,
      stability: row.stability,
      difficulty: row.difficulty,
      due: row.due,
      lastReview: row.lastReviewAt,
    );
    final rated = _scheduler.rate(card, rating, now: at);
    final updated = rated.card;
    final lapsed = rating == Rating.again && card.state == State.review;

    await (_db.update(_db.reviewCards)..where((t) => t.id.equals(cardId)))
        .write(ReviewCardsCompanion(
      state: Value(updated.state.value),
      step: Value(updated.step),
      stability: Value(updated.stability ?? 0),
      difficulty: Value(updated.difficulty ?? 0),
      due: Value(updated.due.toLocal()),
      lastReviewAt: Value(at),
      reps: Value(row.reps + 1),
      lapses: Value(row.lapses + (lapsed ? 1 : 0)),
    ));

    await _db.into(_db.reviewLogs).insert(
          ReviewLogsCompanion.insert(
            questionId: row.questionId,
            rating: rating.value,
            reviewedAt: at,
          ),
        );

    await _updateMastery(row.questionId, updated, row.reps + 1);

    await _db.into(_db.learningEvents).insert(
          LearningEventsCompanion.insert(
            eventType: 'review_done',
            questionId: Value(row.questionId),
            at: at,
            payload: Value(jsonEncode({
              'rating': rating.name,
              'state': updated.state.name,
              'stability': updated.stability,
            })),
          ),
        );
  }

  /// 掌握度映射（供成长引擎的学习能力维度消费）：
  /// 0 新题 → 1-2 学习中 → 3 已入长期（review 态）
  /// 4 稳定（S≥21 天）→ 5 掌握（S≥60 天）
  Future<void> _updateMastery(
    String questionId,
    Card card,
    int reps,
  ) async {
    final stability = card.stability ?? 0;
    final int level;
    if (card.state == State.review) {
      if (stability >= 60) {
        level = 5;
      } else if (stability >= 21) {
        level = 4;
      } else {
        level = 3;
      }
    } else {
      level = reps <= 1 ? 1 : 2;
    }
    await (_db.update(_db.questionRecords)
          ..where((t) => t.id.equals(questionId)))
        .write(QuestionRecordsCompanion(
      masteryLevel: Value(level),
      updatedAt: Value(DateTime.now()),
    ));
  }
}
