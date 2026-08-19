import 'package:ai_study_growth/src/data/services/review_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';

void main() {
  final scheduler = ReviewScheduler();
  final now = DateTime.utc(2026, 8, 18, 10);

  Card newCard() => scheduler.cardFromStorage(
        cardId: 1,
        state: 0,
        stability: 0,
        difficulty: 0,
        due: now,
      );

  test('新卡还原：learning 状态、无 stability/difficulty', () {
    final card = newCard();
    expect(card.state, State.learning);
    expect(card.step, 0);
    expect(card.stability, isNull);
    expect(card.difficulty, isNull);
  });

  test('新卡评 again：停留学习态，约 1 分钟后再现', () {
    final rated = scheduler.rate(newCard(), Rating.again, now: now);
    final updated = rated.card;
    final reviewLog = rated.reviewLog;
    expect(updated.state, State.learning);
    expect(updated.due.difference(now), const Duration(minutes: 1));
    expect(reviewLog.rating, Rating.again);
  });

  test('新卡评 easy：直接进入复习态，间隔至少 1 天', () {
    final updated = scheduler.rate(newCard(), Rating.easy, now: now).card;
    expect(updated.state, State.review);
    expect(updated.stability, isNotNull);
    expect(updated.due.difference(now).inDays, greaterThanOrEqualTo(1));
  });

  test('学习态两步走完（good→good）进入复习态并产生 stability', () {
    var card = newCard();
    card = scheduler.rate(card, Rating.good, now: now).card;
    expect(card.state, State.learning);
    expect(card.step, 1);

    card = scheduler
        .rate(
          card,
          Rating.good,
          now: now.add(const Duration(minutes: 11)),
        )
        .card;
    expect(card.state, State.review);
    expect(card.stability, greaterThan(0));
    expect(card.due.isAfter(now.add(const Duration(days: 1))), isTrue);
  });

  test('复习态评 again：掉入再学习态', () {
    var card = newCard();
    card = scheduler.rate(card, Rating.easy, now: now).card;
    expect(card.state, State.review);

    card = scheduler
        .rate(
          card,
          Rating.again,
          now: now.add(const Duration(days: 1)),
        )
        .card;
    expect(card.state, State.relearning);
  });

  test('未复习卡的可提取率为 0', () {
    expect(scheduler.retrievability(newCard(), now: now), 0);
  });

  group('排期器确定性（Part 3.2：禁 LLM 算间隔）', () {
    test('同输入同评分 → 完全相同的下次到期时间（无随机性）', () {
      final results = <DateTime>[];
      for (var i = 0; i < 5; i++) {
        final s = ReviewScheduler();
        final card = s.cardFromStorage(
          cardId: 1,
          state: 0,
          stability: 0,
          difficulty: 0,
          due: now,
        );
        results.add(s.rate(card, Rating.good, now: now).card.due);
      }
      for (final d in results) {
        expect(d, results.first);
      }
    });

    test('评分单调性：easy 的间隔 ≥ good ≥ hard', () {
      Card freshCard() => scheduler.cardFromStorage(
            cardId: 1,
            state: 0,
            stability: 0,
            difficulty: 0,
            due: now,
          );
      final easyDue =
          scheduler.rate(freshCard(), Rating.easy, now: now).card.due;
      final goodDue =
          scheduler.rate(freshCard(), Rating.good, now: now).card.due;
      final hardDue =
          scheduler.rate(freshCard(), Rating.hard, now: now).card.due;
      expect(easyDue.isAfter(goodDue) || easyDue.isAtSameMomentAs(goodDue),
          isTrue);
      expect(goodDue.isAfter(hardDue), isTrue);
    });

    test('预览间隔与真实评分一致（复习页所见即所得）', () {
      final card = scheduler.cardFromStorage(
        cardId: 1,
        state: 0,
        stability: 0,
        difficulty: 0,
        due: now,
      );
      final previews = scheduler.previewIntervals(card, now: now);
      final actual = scheduler.rate(card, Rating.good, now: now).card.due;
      expect(
        (previews[Rating.good] ?? Duration.zero).inMinutes,
        actual.difference(now).inMinutes,
      );
    });
  });
}
