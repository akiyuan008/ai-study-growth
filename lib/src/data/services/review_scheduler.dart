import 'package:fsrs/fsrs.dart';

/// FSRS 间隔复习引擎 —— 对 [Scheduler] 的薄封装。
///
/// 设计约定：
/// - 新卡（从未复习）在 DB 中 state=0，构造为 learning + stability/difficulty 为空
/// - 已复习卡按 DB 的 state(1/2/3) 还原
/// - 所有时间统一用 UTC（fsrs 强制要求）
class ReviewScheduler {
  ReviewScheduler({Scheduler? scheduler})
      : _scheduler = scheduler ?? Scheduler(enableFuzzing: false);

  final Scheduler _scheduler;

  /// 从持久化字段还原一张 FSRS 卡片
  Card cardFromStorage({
    required int cardId,
    required int state,
    int? step,
    required double stability,
    required double difficulty,
    required DateTime due,
    DateTime? lastReview,
  }) {
    final isNew = state == 0;
    return Card(
      cardId: cardId,
      state: isNew ? State.learning : State.fromValue(state),
      step: isNew ? 0 : step,
      stability: isNew ? null : stability,
      difficulty: isNew ? null : difficulty,
      due: due.toUtc(),
      lastReview: lastReview?.toUtc(),
    );
  }

  /// 评分并得到新卡片状态
  ({Card card, ReviewLog reviewLog}) rate(
    Card card,
    Rating rating, {
    DateTime? now,
  }) {
    return _scheduler.reviewCard(
      card,
      rating,
      reviewDateTime: (now ?? DateTime.now()).toUtc(),
    );
  }

  /// 卡片当前可提取率（0-1），用于展示"记忆强度"
  double retrievability(Card card, {DateTime? now}) =>
      _scheduler.getCardRetrievability(
        card,
        currentDateTime: (now ?? DateTime.now()).toUtc(),
      );
}
