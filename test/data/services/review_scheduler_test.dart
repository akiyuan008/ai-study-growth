import 'package:ai_study_growth/src/data/services/review_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scheduler = Sm2Scheduler();
  final now = DateTime(2026, 8, 21, 10);

  Sm2Card newCard() => scheduler.newCard(cardId: 1);

  group('新卡', () {
    test('初始状态：reps=0 / EF=2.5 / interval=0', () {
      final card = newCard();
      expect(card.reps, 0);
      expect(card.easinessFactor, 2.5);
      expect(card.intervalDays, 0);
      expect(card.statusText, '新题');
    });

    test('评 已会(5)：首次间隔 1 天，EF 上升', () {
      final rated = scheduler.rate(newCard(), 5, now: now);
      expect(rated.card.intervalDays, 1);
      expect(rated.card.reps, 1);
      expect(rated.card.due, now.add(const Duration(days: 1)));
      expect(rated.card.easinessFactor, greaterThan(2.5));
    });

    test('评 仍错(1)：间隔重置 1 天，reps 归零，EF 下降', () {
      final rated = scheduler.rate(newCard(), 1, now: now);
      expect(rated.card.intervalDays, 1);
      expect(rated.card.reps, 0);
      expect(rated.card.easinessFactor, lessThan(2.5));
    });
  });

  group('连续复习', () {
    test('连续 已会：间隔逐次拉长（仍错变早/已会变晚的方向性）', () {
      var card = newCard();
      final intervals = <int>[];
      for (var i = 0; i < 4; i++) {
        card = scheduler.rate(card, 5, now: now).card;
        intervals.add(card.intervalDays);
      }
      // 严格递增
      for (var i = 1; i < intervals.length; i++) {
        expect(intervals[i], greaterThan(intervals[i - 1]));
      }
    });

    test('长间隔后评 仍错：打回 1 天重来', () {
      var card = newCard();
      for (var i = 0; i < 5; i++) {
        card = scheduler.rate(card, 5, now: now).card;
      }
      expect(card.intervalDays, greaterThan(5));
      final lapsed = scheduler.rate(card, 1, now: now).card;
      expect(lapsed.intervalDays, 1);
      expect(lapsed.reps, 0);
    });

    test('EF 下限 1.3：连续 仍错 不再下降', () {
      var card = newCard();
      for (var i = 0; i < 10; i++) {
        card = scheduler.rate(card, 1, now: now).card;
      }
      expect(card.easinessFactor, greaterThanOrEqualTo(1.3));
    });

    test('EF 上限 3.0：连续 已会 不再上升', () {
      var card = newCard();
      for (var i = 0; i < 30; i++) {
        card = scheduler.rate(card, 5, now: now).card;
      }
      expect(card.easinessFactor, lessThanOrEqualTo(3.0));
    });
  });

  group('预览与实际一致', () {
    test('previewIntervals 三档 == 真实 rate 结果', () {
      final card = scheduler.rate(newCard(), 5, now: now).card;
      final preview = scheduler.previewIntervals(card, now: now);
      for (final q in [1, 3, 5]) {
        expect(preview[q],
            scheduler.rate(card, q, now: now).card.due.difference(now));
      }
    });

    test('仍错预览 == 1 天', () {
      final preview = scheduler.previewIntervals(newCard(), now: now);
      expect(preview[1], const Duration(days: 1));
    });
  });

  group('到期判断', () {
    test('isDue / overdueDays', () {
      final due = now.subtract(const Duration(days: 3));
      final card = Sm2Card(
        cardId: 1,
        reps: 1,
        easinessFactor: 2.5,
        intervalDays: 1,
        due: due,
      );
      expect(scheduler.isDue(card, now: now), isTrue);
      expect(scheduler.overdueDays(card, now: now), 3);
      final future = Sm2Card(
        cardId: 2,
        reps: 1,
        easinessFactor: 2.5,
        intervalDays: 1,
        due: now.add(const Duration(days: 1)),
      );
      expect(scheduler.isDue(future, now: now), isFalse);
      expect(scheduler.overdueDays(future, now: now), 0);
    });
  });

  group('日志', () {
    test('reviewLog 记录前后 EF/间隔', () {
      final card = scheduler.rate(newCard(), 5, now: now).card;
      final rated =
          scheduler.rate(card, 1, now: now.add(const Duration(days: 1)));
      expect(rated.reviewLog.quality, 1);
      expect(rated.reviewLog.qualityLabel, '仍错');
      expect(rated.reviewLog.previousInterval, card.intervalDays);
      expect(rated.reviewLog.newInterval, 1);
    });
  });
}
