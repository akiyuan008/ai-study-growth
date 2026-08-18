import 'package:ai_study_growth/src/core/growth/growth_engine.dart';
import 'package:flutter_test/flutter_test.dart';

GrowthInput base({
  int focusMs = 0,
  int distractionCount = 0,
  int distractionRecoveries = 0,
  int reviewDone = 0,
  int reviewDue = 0,
  int newQuestions = 0,
  int masteryGains = 0,
  int streak = 0,
  bool missedYesterday = false,
}) =>
    GrowthInput(
      focusMs: focusMs,
      distractionCount: distractionCount,
      distractionRecoveries: distractionRecoveries,
      reviewDone: reviewDone,
      reviewDue: reviewDue,
      newQuestions: newQuestions,
      masteryGains: masteryGains,
      streak: streak,
      missedYesterday: missedYesterday,
    );

void main() {
  test('充实的一天：四项能力都高', () {
    final scores = GrowthEngine.compute(base(
      focusMs: 130 * 60 * 1000,
      reviewDone: 8,
      reviewDue: 8,
      newQuestions: 4,
      masteryGains: 3,
      streak: 10,
    ));
    expect(scores.learning, greaterThanOrEqualTo(90));
    expect(scores.focus, greaterThanOrEqualTo(90));
    expect(scores.persistence, greaterThanOrEqualTo(90));
    expect(scores.overall, greaterThan(0.8));
    expect(GrowthIdentity.describe(scores), '蓬勃生长者');
  });

  test('躺平的一天：分数全面走低', () {
    final scores = GrowthEngine.compute(base());
    expect(scores.focus, 0);
    expect(scores.learning, lessThan(50));
    expect(scores.persistence, 0);
    expect(GrowthIdentity.describe(scores), '刚刚起步者');
  });

  test('分心多但都回归：恢复能力高，专注被轻罚', () {
    final recovered = GrowthEngine.compute(base(
      focusMs: 60 * 60 * 1000,
      distractionCount: 4,
      distractionRecoveries: 4,
      streak: 3,
    ));
    final notRecovered = GrowthEngine.compute(base(
      focusMs: 60 * 60 * 1000,
      distractionCount: 4,
      distractionRecoveries: 1,
      streak: 3,
    ));
    expect(recovered.recovery, greaterThan(notRecovered.recovery));
    expect(recovered.focus, equals(notRecovered.focus));
  });

  test('昨日断档今日回归：恢复能力被奖励，坚持被压制', () {
    final comeback = GrowthEngine.compute(base(
      focusMs: 30 * 60 * 1000,
      streak: 1,
      missedYesterday: true,
    ));
    final steady = GrowthEngine.compute(base(
      focusMs: 30 * 60 * 1000,
      streak: 1,
      missedYesterday: false,
    ));
    expect(comeback.recovery, greaterThan(steady.recovery));
    expect(comeback.persistence, lessThan(30));
  });

  test('复习完成率驱动学习能力：做一半 < 全做完', () {
    final half = GrowthEngine.compute(base(reviewDone: 4, reviewDue: 8));
    final full = GrowthEngine.compute(base(reviewDone: 8, reviewDue: 8));
    expect(full.learning, greaterThan(half.learning));
  });

  test('能力分数始终在 0-100', () {
    final extreme = GrowthEngine.compute(base(
      focusMs: 999 * 60 * 1000,
      distractionCount: 100,
      distractionRecoveries: 200,
      reviewDone: 999,
      reviewDue: 10,
      newQuestions: 999,
      masteryGains: 999,
      streak: 9999,
    ));
    for (final v in [
      extreme.learning,
      extreme.focus,
      extreme.persistence,
      extreme.recovery,
    ]) {
      expect(v, inInclusiveRange(0, 100));
    }
  });

  test('最强能力识别', () {
    final scores = GrowthEngine.compute(base(
      focusMs: 130 * 60 * 1000,
      streak: 1,
    ));
    expect(GrowthIdentity.strongest(scores), '专注');
  });
}
