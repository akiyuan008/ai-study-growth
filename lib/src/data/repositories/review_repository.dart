import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../services/review_scheduler.dart';

/// 到期复习卡 + 关联题目
class DueReviewItem {
  const DueReviewItem({required this.card, required this.question});

  final ReviewCard card;
  final QuestionRecord question;
}

/// 复习仓储：SM-2 卡片调度 + 复习日志 + 掌握度联动 + 学习事件
class ReviewRepository {
  ReviewRepository(this._db, {Sm2Scheduler? scheduler})
      : _scheduler = scheduler ?? Sm2Scheduler();

  final AppDatabase _db;
  final Sm2Scheduler _scheduler;

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

  /// 评分：跑 SM-2 → 回写卡片 → 写日志 → 更新掌握度 → 发学习事件
  /// quality: 1=仍错, 3=模糊, 5=已会
  Future<void> rate({
    required String cardId,
    required int quality,
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
      reps: row.reps,
      easinessFactor: row.easinessFactor,
      intervalDays: row.intervalDays,
      due: row.due,
      lastReview: row.lastReviewAt,
    );
    final rated = _scheduler.rate(card, quality, now: at);
    final updated = rated.card;

    await (_db.update(_db.reviewCards)..where((t) => t.id.equals(cardId)))
        .write(ReviewCardsCompanion(
      easinessFactor: Value(updated.easinessFactor),
      intervalDays: Value(updated.intervalDays),
      due: Value(updated.due.toLocal()),
      lastReviewAt: Value(at),
      reps: Value(updated.reps),
      lapses: Value(row.lapses + (quality < 3 ? 1 : 0)),
    ));

    await _db.into(_db.reviewLogs).insert(
          ReviewLogsCompanion.insert(
            questionId: row.questionId,
            rating: quality,
            reviewedAt: at,
          ),
        );

    await _updateMastery(row.questionId, updated, updated.reps);
  }

  /// 掌握度映射（SM-2 版）：
  /// 0 新题 → 1-2 学习中 → 3 已入长期（reps > 0）
  /// 4 稳定（intervalDays≥21 天）→ 5 已掌握（intervalDays≥60 且 reps≥3）
  Future<void> _updateMastery(
    String questionId,
    Sm2Card card,
    int reps,
  ) async {
    final int level;
    if (reps >= 3 && card.intervalDays >= 60) {
      level = 5; // 已掌握
    } else if (card.intervalDays >= 60) {
      level = 5;
    } else if (card.intervalDays >= 21) {
      level = 4;
    } else if (reps > 0) {
      level = 3;
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
