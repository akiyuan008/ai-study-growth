/// 成长引擎 v10 —— 三能力模型（专注域已删除）。
///
/// 设计原则：
/// - 能力是趋势而非属性：只产出 0-100 趋势分，UI 层转定性描述
/// - 每个分数有可解释的事实输入
/// - 纯函数，可测试
class GrowthInput {
  const GrowthInput({
    required this.reviewDone,
    required this.reviewDue,
    required this.newQuestions,
    required this.masteryGains,
    required this.exerciseDone,
    required this.streak,
    required this.missedYesterday,
    required this.lapseRecoveries,
    required this.lapses,
  });

  // ---- 学习域事实 ----
  final int reviewDone;
  final int reviewDue;
  final int newQuestions;

  /// 今日掌握度提升的题目数
  final int masteryGains;

  /// 今日完成的举一反三练习数
  final int exerciseDone;

  // ---- 跨域事实 ----
  final int streak;

  /// 昨天是否断档
  final bool missedYesterday;

  /// 错后重做正确次数（lapse 后 good/easy）
  final int lapseRecoveries;

  /// 总遗忘次数
  final int lapses;
}

class GrowthScores {
  const GrowthScores({
    required this.learning,
    required this.persistence,
    required this.recovery,
  });

  final double learning;
  final double persistence;
  final double recovery;

  /// 综合趋势 0-1
  double get overall => (learning + persistence + recovery) / 300;
}

/// GrowthCalculator 输出：三能力分数 + 今日是否有过任何活动
class GrowthCalcResult {
  const GrowthCalcResult({required this.scores, required this.hasAnyActivity});

  final GrowthScores scores;
  final bool hasAnyActivity;
}

abstract final class GrowthEngine {
  static GrowthCalcResult calculate(GrowthInput input) {
    final hasAnyActivity = input.reviewDone > 0 ||
        input.newQuestions > 0 ||
        input.exerciseDone > 0 ||
        input.masteryGains > 0;
    return GrowthCalcResult(
      scores: compute(input),
      hasAnyActivity: hasAnyActivity,
    );
  }

  static GrowthScores compute(GrowthInput input) {
    return GrowthScores(
      learning: _learning(input),
      persistence: _persistence(input),
      recovery: _recovery(input),
    );
  }

  /// 学习能力 = 复习完成率 50% + 掌握度提升 30% + 举一反三完成 20%
  static double _learning(GrowthInput i) {
    final hasActivity = i.reviewDone > 0 || i.newQuestions > 0;
    final reviewScore = i.reviewDue <= 0
        ? (i.reviewDone > 0 ? 1.0 : (hasActivity ? 0.6 : 0.2))
        : (i.reviewDone / i.reviewDue).clamp(0.0, 1.0);
    final masteryScore = (i.masteryGains / 2).clamp(0.0, 1.0);
    final exerciseScore = (i.exerciseDone / 3).clamp(0.0, 1.0);
    return _scale(reviewScore * 0.5 + masteryScore * 0.3 + exerciseScore * 0.2);
  }

  /// 坚持能力 = 连续天数 60% + 计划执行率（复习执行）40%
  static double _persistence(GrowthInput i) {
    if (i.missedYesterday && i.streak <= 1) return _scale(0.15);
    final streakScore = (i.streak / 7).clamp(0.0, 1.0);
    final executionScore = i.reviewDue <= 0
        ? (i.reviewDone > 0 ? 1.0 : 0.4)
        : (i.reviewDone / i.reviewDue).clamp(0.0, 1.0);
    return _scale(streakScore * 0.6 + executionScore * 0.4);
  }

  /// 恢复能力 = 复发错题重做正确率 60% + 中断后回归 40%
  static double _recovery(GrowthInput i) {
    // 完全无活动的一天谈不上恢复
    final hasActivity =
        i.reviewDone > 0 || i.newQuestions > 0 || i.exerciseDone > 0;
    if (!hasActivity) {
      return _scale(i.missedYesterday ? 0.1 : 0.25);
    }
    // 错后重做正确率
    final lapseRate = i.lapses > 0
        ? (i.lapseRecoveries / i.lapses).clamp(0.0, 1.0)
        : 0.7; // 无遗忘记录：中性偏上
    // 中断后回归：昨日断档但今日有活动 = 强恢复
    final comeback = i.missedYesterday ? (i.streak >= 1 ? 1.0 : 0.2) : 0.7;
    return _scale(lapseRate * 0.6 + comeback * 0.4);
  }

  static double _scale(double ratio) => (ratio * 100).roundToDouble();
}

/// 定性身份描述（不显示分数）
abstract final class GrowthIdentity {
  static String describe(GrowthScores scores) {
    final overall = scores.overall;
    if (overall >= 0.75) return '蓬勃生长者';
    if (overall >= 0.5) return '稳步前进者';
    if (overall >= 0.25) return '积蓄力量者';
    return '刚刚起步者';
  }

  static String strongest(GrowthScores scores) {
    final entries = {
      '学习': scores.learning,
      '坚持': scores.persistence,
      '恢复': scores.recovery,
    }.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}
