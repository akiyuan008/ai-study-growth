import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// 遗忘曲线小图（v13 6.5）：FSRS 保留率曲线 R(t) = (1 + t/(9S))^(-1)
/// 作为推荐理由的解释图与记忆状态卡的可视化。
class ForgettingCurveMini extends StatelessWidget {
  const ForgettingCurveMini({
    super.key,
    required this.stability,
    required this.elapsedDays,
    this.nextDueDays,
    this.height = 44,
    this.color,
  });

  /// FSRS 记忆稳定度（天）
  final double stability;

  /// 距上次复习已过去的天数
  final double elapsedDays;

  /// 下次复习间隔（天），用于标注竖线
  final double? nextDueDays;
  final double height;
  final Color? color;

  /// 保留率（0-1）
  static double retention(double t, double s) {
    if (s <= 0) return 0;
    return math.pow(1 + t / (9 * s), -1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final c =
        color ?? (isLight ? GrowthColors.primary : GrowthColors.primaryDark);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CurvePainter(
          stability: stability,
          elapsedDays: elapsedDays,
          nextDueDays: nextDueDays,
          color: c,
          trackColor: isLight
              ? GrowthColors.ringTrackLight
              : GrowthColors.ringTrackDark,
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.stability,
    required this.elapsedDays,
    required this.nextDueDays,
    required this.color,
    required this.trackColor,
  });

  final double stability;
  final double elapsedDays;
  final double? nextDueDays;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = math.max(
      math.max((nextDueDays ?? 0) * 1.4, elapsedDays * 1.4),
      math.max(stability * 2, 7.0),
    );

    final path = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = horizon * i / steps;
      final r = ForgettingCurveMini.retention(t, stability);
      final x = size.width * i / steps;
      final y = size.height * (1 - r * 0.92) - 1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    // 当前时刻竖线
    if (elapsedDays > 0 && horizon > 0) {
      final x = size.width * (elapsedDays / horizon).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 0.55),
      );
    }

    // 下次复习竖线（虚线）
    final due = nextDueDays;
    if (due != null && due > 0 && horizon > 0) {
      final x = size.width * (due / horizon).clamp(0.0, 1.0);
      final dash = Paint()
        ..strokeWidth = 1.2
        ..color = trackColor;
      for (var y = 0.0; y < size.height; y += 6) {
        canvas.drawLine(
            Offset(x, y), Offset(x, math.min(y + 3, size.height)), dash);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.stability != stability ||
      oldDelegate.elapsedDays != elapsedDays ||
      oldDelegate.nextDueDays != nextDueDays;
}

/// 间隔历史 chips：第1次 1天 → 第2次 3天 …
class IntervalHistoryChips extends StatelessWidget {
  const IntervalHistoryChips({super.key, required this.intervals});

  final List<int> intervals;

  @override
  Widget build(BuildContext context) {
    if (intervals.isEmpty) {
      return Text(
        '首次复习',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Wrap(
      spacing: GrowthSpacing.xs,
      runSpacing: GrowthSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, d) in intervals.indexed) ...[
          if (i > 0)
            Icon(Icons.arrow_forward_rounded,
                size: 10, color: GrowthColors.gray4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: GrowthColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GrowthRadii.icon),
            ),
            child: Text(
              d == 0 ? '<1天' : '$d天',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: GrowthColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
