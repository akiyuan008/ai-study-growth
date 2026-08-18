import 'dart:math' as math;

/// 成长引擎 —— 从双域真实数据计算四能力趋势。
///
/// 设计原则（用户拍板）：
/// - 能力是趋势而非属性：只产出 0-100 的趋势分，UI 层转成定性描述
/// - 每个分数必须有可解释的事实输入，不拍脑袋
/// - 纯函数，可测试，输入全部来自 Drift 事实表
class GrowthInput {
  const GrowthInput({
    required this.focusMs,
    required this.distractionCount,
    required this.distractionRecoveries,
    required this.reviewDone,
    required this.reviewDue,
    required this.newQuestions,
    required this.masteryGains,
    required this.streak,
    required this.missedYesterday,
  });

  // ---- 自律域事实 ----
  final int focusMs;
  final int distractionCount;

  /// 分心后回归专注的次数（恢复行为）
  final int distractionRecoveries;

  // ---- 学习域事实 ----
  final int reviewDone;
  final int reviewDue;
  final int newQuestions;

  /// 今日掌握度提升的题目数（mastery level 上涨）
  final int masteryGains;

  // ---- 跨域事实 ----
  final int streak;

  /// 昨天是否断档（无任何学习/专注行为）
  final bool missedYesterday;
}

class GrowthScores {
  const GrowthScores({
    required this.learning,
    required this.focus,
    required this.persistence,
    required this.recovery,
  });

  final double learning;
  final double focus;
  final double persistence;
  final double recovery;

  /// 综合趋势 0-1
  double get overall => (learning + focus + persistence + recovery) / 400;
}

/// GrowthCalculator 输出：四能力分数 + 今日是否有过任何活动
class GrowthCalcResult {
  const GrowthCalcResult({required this.scores, required this.hasAnyActivity});

  final GrowthScores scores;
  final bool hasAnyActivity;
}

abstract final class GrowthEngine {
  /// 专注目标：每日 120 分钟 = 满分
  static const int focusTargetMs = 120 * 60 * 1000;

  /// 完整计算：分数 + hasAnyActivity 标志（Prompt B 规则）
  static GrowthCalcResult calculate(GrowthInput input) {
    final hasAnyActivity = input.focusMs > 0 ||
        input.reviewDone > 0 ||
        input.newQuestions > 0 ||
        input.distractionCount > 0;
    return GrowthCalcResult(
      scores: compute(input),
      hasAnyActivity: hasAnyActivity,
    );
  }

  static GrowthScores compute(GrowthInput input) {
    return GrowthScores(
      learning: _learning(input),
      focus: _focus(input),
      persistence: _persistence(input),
      recovery: _recovery(input),
    );
  }

  /// 学习能力：复习完成度 60% + 新题摄入 20% + 掌握度提升 20%
  static double _learning(GrowthInput i) {
    final hasActivity = i.focusMs > 0 || i.newQuestions > 0 || i.reviewDone > 0;
    final reviewScore = i.reviewDue <= 0
        ? (i.reviewDone > 0
            ? 1.0
            : hasActivity
                ? 0.6 // 无到期复习但其他在学习 = 基础分
                : 0.2) // 完全没动 = 低分
        : (i.reviewDone / i.reviewDue).clamp(0.0, 1.0);

    final intakeScore = (i.newQuestions / 3).clamp(0.0, 1.0);
    final masteryScore = (i.masteryGains / 2).clamp(0.0, 1.0);

    return _scale(reviewScore * 0.6 + intakeScore * 0.2 + masteryScore * 0.2);
  }

  /// 专注能力：真实专注时长对标目标，分心按次轻罚
  static double _focus(GrowthInput i) {
    final base = (i.focusMs / focusTargetMs).clamp(0.0, 1.0);
    final penalty = math.min(0.3, i.distractionCount * 0.05);
    return _scale((base - penalty).clamp(0.0, 1.0));
  }

  /// 坚持能力：连续天数为主，昨日断档重罚
  static double _persistence(GrowthInput i) {
    if (i.missedYesterday && i.streak <= 1) return _scale(0.15);
    final streakScore = (i.streak / 7).clamp(0.0, 1.0);
    return _scale(streakScore);
  }

  /// 恢复能力：分心后回归率 + 断档后重新起步
  static double _recovery(GrowthInput i) {
    if (i.distractionCount > 0) {
      final rate =
          (i.distractionRecoveries / i.distractionCount).clamp(0.0, 1.0);
      return _scale(rate * 0.8 + 0.1);
    }
    // 完全无活动的一天谈不上恢复，给低分
    final hasActivity = i.focusMs > 0 || i.newQuestions > 0 || i.reviewDone > 0;
    if (!hasActivity) {
      return _scale(i.missedYesterday ? 0.1 : 0.25);
    }
    // 无分心：看是否从昨日断档中恢复
    if (i.missedYesterday && i.streak >= 1) return _scale(0.9);
    return _scale(0.7); // 平稳的一天，给中性偏上
  }

  static double _scale(double ratio) => (ratio * 100).roundToDouble();
}

/// 定性身份描述（不显示分数，Growth Mode 产品原则）
abstract final class GrowthIdentity {
  static String describe(GrowthScores scores) {
    final overall = scores.overall;
    if (overall >= 0.75) return '蓬勃生长者';
    if (overall >= 0.5) return '稳步前进者';
    if (overall >= 0.25) return '积蓄力量者';
    return '刚刚起步者';
  }

  /// 找出最强能力，作为身份注脚
  static String strongest(GrowthScores scores) {
    final entries = {
      '学习': scores.learning,
      '专注': scores.focus,
      '坚持': scores.persistence,
      '恢复': scores.recovery,
    }.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}
