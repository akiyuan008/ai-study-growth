import 'package:ai_study_growth/src/core/growth/growth_engine.dart';
import 'package:flutter_test/flutter_test.dart';

GrowthInput base({
  int reviewDone = 0,
  int reviewDue = 0,
  int newQuestions = 0,
  int masteryGains = 0,
  int exerciseDone = 0,
  int streak = 0,
  bool missedYesterday = false,
  int lapseRecoveries = 0,
  int lapses = 0,
}) =>
    GrowthInput(
      reviewDone: reviewDone,
      reviewDue: reviewDue,
      newQuestions: newQuestions,
      masteryGains: masteryGains,
      exerciseDone: exerciseDone,
      streak: streak,
      missedYesterday: missedYesterday,
      lapseRecoveries: lapseRecoveries,
      lapses: lapses,
    );

void main() {
  test('充实的一天：三项能力都高', () {
    final scores = GrowthEngine.compute(base(
      reviewDone: 8,
      reviewDue: 8,
      newQuestions: 4,
      masteryGains: 3,
      exerciseDone: 3,
      streak: 10,
    ));
    expect(scores.learning, greaterThanOrEqualTo(85));
    expect(scores.persistence, greaterThanOrEqualTo(90));
    expect(scores.overall, greaterThan(0.7));
    expect(GrowthIdentity.describe(scores), '蓬勃生长者');
  });

  test('躺平的一天：分数全面走低', () {
    final scores = GrowthEngine.compute(base());
    expect(scores.learning, lessThan(40));
    expect(scores.persistence, lessThan(20));
    expect(GrowthIdentity.describe(scores), '刚刚起步者');
  });

  test('错后重做正确：恢复能力高', () {
    final recovered = GrowthEngine.compute(base(
      reviewDone: 4,
      reviewDue: 4,
      streak: 3,
      lapses: 3,
      lapseRecoveries: 3,
    ));
    final notRecovered = GrowthEngine.compute(base(
      reviewDone: 4,
      reviewDue: 4,
      streak: 3,
      lapses: 3,
      lapseRecoveries: 0,
    ));
    expect(recovered.recovery, greaterThan(notRecovered.recovery));
  });

  test('昨日断档今日回归：恢复被奖励，坚持被压制', () {
    final comeback = GrowthEngine.compute(base(
      reviewDone: 2,
      streak: 1,
      missedYesterday: true,
    ));
    final steady = GrowthEngine.compute(base(
      reviewDone: 2,
      streak: 1,
      missedYesterday: false,
    ));
    expect(comeback.recovery, greaterThan(steady.recovery));
    expect(comeback.persistence, lessThan(60));
  });

  test('复习完成率驱动学习能力', () {
    final half = GrowthEngine.compute(base(reviewDone: 4, reviewDue: 8));
    final full = GrowthEngine.compute(base(reviewDone: 8, reviewDue: 8));
    expect(full.learning, greaterThan(half.learning));
  });

  test('能力分数始终在 0-100', () {
    final extreme = GrowthEngine.compute(base(
      reviewDone: 999,
      reviewDue: 10,
      newQuestions: 999,
      masteryGains: 999,
      exerciseDone: 999,
      streak: 9999,
      lapses: 1,
      lapseRecoveries: 999,
    ));
    for (final v in [
      extreme.learning,
      extreme.persistence,
      extreme.recovery,
    ]) {
      expect(v, inInclusiveRange(0, 100));
    }
  });

  group('GrowthCalculator hasAnyActivity（Prompt B 规则）', () {
    test('全零输入：无活动标志，环图进新用户态', () {
      final result = GrowthEngine.calculate(base());
      expect(result.hasAnyActivity, isFalse);
      expect(result.scores.persistence, lessThan(20));
      expect(result.scores.learning, lessThan(20));
      expect(result.scores.recovery, lessThan(30));
    });

    test('单能力非零（只有复习）：判定为有活动', () {
      final result = GrowthEngine.calculate(base(reviewDone: 1));
      expect(result.hasAnyActivity, isTrue);
      expect(result.scores.learning, greaterThan(0));
    });

    test('全部非零：判定为有活动', () {
      final result = GrowthEngine.calculate(base(
        reviewDone: 5,
        reviewDue: 5,
        newQuestions: 2,
        masteryGains: 1,
        exerciseDone: 2,
        streak: 4,
      ));
      expect(result.hasAnyActivity, isTrue);
      for (final v in [
        result.scores.learning,
        result.scores.persistence,
        result.scores.recovery,
      ]) {
        expect(v, greaterThan(0));
      }
    });
  });

  test('最强能力识别', () {
    final scores = GrowthEngine.compute(base(
      reviewDone: 8,
      reviewDue: 8,
      streak: 1,
    ));
    expect(GrowthIdentity.strongest(scores), isNotEmpty);
  });
}
