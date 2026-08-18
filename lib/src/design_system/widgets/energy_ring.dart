import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// 能量环的一段能力弧
class AbilityArc {
  const AbilityArc({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;

  /// 0.0 ~ 1.0，超出会被钳制
  final double value;
  final Color color;
}

/// 成长能量环 —— 成长引擎的可视化载体。
///
/// 四能力（学习/专注/坚持/恢复）以四段圆弧呈现，
/// 弧的填充比例即能力趋势值，一眼看到「涨落」。
/// 不显示具体分数是 Growth Mode 的产品原则，
/// 中心默认为综合趋势的定性展示，可通过 [centerWidget] 覆盖。
class EnergyRing extends StatefulWidget {
  const EnergyRing({
    super.key,
    required this.arcs,
    this.size = 220,
    this.strokeWidth = 14,
    this.centerWidget,
    this.animate = true,
    this.idle = false,
    this.onTap,
  });

  final List<AbilityArc> arcs;
  final double size;
  final double strokeWidth;
  final Widget? centerWidget;
  final bool animate;

  /// 新用户态（Prompt B）：不绘制任何彩色弧，只显示全灰轨道
  final bool idle;

  /// 点按环体（弹出能力明细）
  final VoidCallback? onTap;

  @override
  State<EnergyRing> createState() => _EnergyRingState();
}

class _EnergyRingState extends State<EnergyRing> {
  @override
  Widget build(BuildContext context) {
    final ring = CustomPaint(
      size: Size.square(widget.size),
      painter: _EnergyRingPainter(
        arcs: widget.arcs,
        strokeWidth: widget.strokeWidth,
        idle: widget.idle,
        trackColor: Theme.of(context).brightness == Brightness.light
            ? const Color(0x14101828)
            : const Color(0x29FFFFFF),
      ),
    );

    final center = widget.centerWidget ??
        _DefaultCenter(
          arcs: widget.arcs,
        );

    final content = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: ring),
          center,
        ],
      ),
    );

    final tappable = widget.onTap == null
        ? content
        : GestureDetector(onTap: widget.onTap, child: content);

    if (!widget.animate) return tappable;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GrowthMotion.ring,
      curve: GrowthMotion.standard,
      builder: (context, t, child) {
        return Opacity(
          opacity: 0.35 + 0.65 * t,
          child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        );
      },
      child: tappable,
    );
  }
}

class _DefaultCenter extends StatelessWidget {
  const _DefaultCenter({required this.arcs});

  final List<AbilityArc> arcs;

  @override
  Widget build(BuildContext context) {
    final avg = arcs.isEmpty
        ? 0.0
        : arcs.map((a) => a.value.clamp(0.0, 1.0)).reduce((a, b) => a + b) /
            arcs.length;
    final label = switch (avg) {
      >= 0.75 => '蓬勃生长',
      >= 0.5 => '稳步成长',
      >= 0.25 => '正在积蓄',
      _ => '等待发芽',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: GrowthSpacing.xs),
        Text(
          '四能力综合趋势',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EnergyRingPainter extends CustomPainter {
  _EnergyRingPainter({
    required this.arcs,
    required this.strokeWidth,
    required this.trackColor,
    this.idle = false,
  });

  final List<AbilityArc> arcs;
  final double strokeWidth;
  final Color trackColor;
  final bool idle;

  static const double _gapDegrees = 16;
  static const double _segmentDegrees = 90 - _gapDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 新用户态：只画一圈全灰轨道，不画任何彩色弧（Prompt B 规则 1）
    if (idle || arcs.isEmpty) {
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = trackColor,
      );
      return;
    }

    // 从正上方开始，顺时针排布
    double startAngle = -90 + _gapDegrees / 2;

    for (final arc in arcs.take(4)) {
      // 轨道
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = trackColor;
      canvas.drawArc(
        rect,
        _deg(startAngle),
        _deg(_segmentDegrees),
        false,
        trackPaint,
      );

      // 能力填充（Prompt B 规则 2：得分为 0 一律不画彩色弧，杜绝零值残弧）
      final value = arc.value.clamp(0.0, 1.0);
      if (value > 0) {
        final fillPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = arc.color;
        canvas.drawArc(
          rect,
          _deg(startAngle),
          _deg(_segmentDegrees * value),
          false,
          fillPaint,
        );
      }

      startAngle += _segmentDegrees + _gapDegrees;
    }
  }

  double _deg(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant _EnergyRingPainter oldDelegate) =>
      oldDelegate.arcs != arcs ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.idle != idle;
}
