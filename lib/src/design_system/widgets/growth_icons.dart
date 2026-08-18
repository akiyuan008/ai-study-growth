import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 自定义线性图标集（Prompt H：禁用 Material Icons 默认件）。
/// 全部手绘路径，支持 outline / filled 两种形态：
/// 未选中 = 线性灰，选中 = 主色填充。
class GrowthIcon extends StatelessWidget {
  const GrowthIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.filled = false,
    this.color,
  });

  final GrowthIconType type;
  final double size;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(type: type, filled: filled, color: base),
    );
  }
}

enum GrowthIconType { sprout, book, camera, target, gear, backArrow }

class _IconPainter extends CustomPainter {
  _IconPainter({
    required this.type,
    required this.filled,
    required this.color,
  });

  final GrowthIconType type;
  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    switch (type) {
      case GrowthIconType.sprout:
        _sprout(canvas, size, stroke, fill);
      case GrowthIconType.book:
        _book(canvas, size, stroke, fill);
      case GrowthIconType.camera:
        _camera(canvas, size, stroke, fill);
      case GrowthIconType.target:
        _target(canvas, size, stroke, fill);
      case GrowthIconType.gear:
        _gear(canvas, size, stroke, fill);
      case GrowthIconType.backArrow:
        _backArrow(canvas, size, stroke);
    }
  }

  void _sprout(Canvas c, Size s, Paint stroke, Paint fill) {
    final w = s.width;
    // 土壤线
    c.drawLine(Offset(w * 0.22, w * 0.82), Offset(w * 0.78, w * 0.82), stroke);
    // 茎
    final stem = Path()
      ..moveTo(w * 0.5, w * 0.82)
      ..cubicTo(w * 0.48, w * 0.62, w * 0.52, w * 0.5, w * 0.5, w * 0.34);
    c.drawPath(stem, stroke);
    // 左叶
    final left = Path()
      ..moveTo(w * 0.5, w * 0.52)
      ..cubicTo(w * 0.3, w * 0.5, w * 0.24, w * 0.34, w * 0.32, w * 0.26)
      ..cubicTo(w * 0.44, w * 0.28, w * 0.5, w * 0.4, w * 0.5, w * 0.52);
    if (filled) c.drawPath(left, fill);
    c.drawPath(left, stroke);
    // 右叶
    final right = Path()
      ..moveTo(w * 0.5, w * 0.42)
      ..cubicTo(w * 0.7, w * 0.4, w * 0.76, w * 0.24, w * 0.68, w * 0.16)
      ..cubicTo(w * 0.56, w * 0.18, w * 0.5, w * 0.3, w * 0.5, w * 0.42);
    if (filled) c.drawPath(right, fill);
    c.drawPath(right, stroke);
  }

  void _book(Canvas c, Size s, Paint stroke, Paint fill) {
    final w = s.width;
    final left = Path()
      ..moveTo(w * 0.5, w * 0.3)
      ..cubicTo(w * 0.38, w * 0.22, w * 0.26, w * 0.22, w * 0.18, w * 0.28)
      ..lineTo(w * 0.18, w * 0.72)
      ..cubicTo(w * 0.26, w * 0.66, w * 0.38, w * 0.66, w * 0.5, w * 0.74);
    final right = Path()
      ..moveTo(w * 0.5, w * 0.3)
      ..cubicTo(w * 0.62, w * 0.22, w * 0.74, w * 0.22, w * 0.82, w * 0.28)
      ..lineTo(w * 0.82, w * 0.72)
      ..cubicTo(w * 0.74, w * 0.66, w * 0.62, w * 0.66, w * 0.5, w * 0.74);
    if (filled) {
      c.drawPath(left..close(), fill);
      c.drawPath(right..close(), fill);
    }
    c.drawPath(left, stroke);
    c.drawPath(right, stroke);
    c.drawLine(Offset(w * 0.5, w * 0.3), Offset(w * 0.5, w * 0.74), stroke);
  }

  void _camera(Canvas c, Size s, Paint stroke, Paint fill) {
    final w = s.width;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, w * 0.3, w * 0.72, w * 0.48),
      Radius.circular(w * 0.1),
    );
    if (filled) c.drawRRect(body, fill);
    c.drawRRect(body, stroke);
    // 顶部凸起
    final top = Path()
      ..moveTo(w * 0.36, w * 0.3)
      ..lineTo(w * 0.4, w * 0.2)
      ..lineTo(w * 0.6, w * 0.2)
      ..lineTo(w * 0.64, w * 0.3);
    c.drawPath(top, stroke);
    // 镜头：filled 模式下画白圈，outline 模式画主色圈
    final lensStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = filled ? Colors.white : color;
    c.drawCircle(Offset(w * 0.5, w * 0.54), w * 0.14, lensStroke);
  }

  void _target(Canvas c, Size s, Paint stroke, Paint fill) {
    final w = s.width;
    final center = Offset(w * 0.5, w * 0.5);
    c.drawCircle(center, w * 0.34, stroke);
    c.drawCircle(center, w * 0.2, stroke);
    if (filled) {
      c.drawCircle(center, w * 0.09, fill);
    } else {
      c.drawCircle(center, w * 0.055, fill);
    }
  }

  void _gear(Canvas c, Size s, Paint stroke, Paint fill) {
    final w = s.width;
    final center = Offset(w * 0.5, w * 0.5);
    // 齿：8 条径向短线
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final inner = Offset(
        center.dx + math.cos(angle) * w * 0.3,
        center.dy + math.sin(angle) * w * 0.3,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * w * 0.42,
        center.dy + math.sin(angle) * w * 0.42,
      );
      c.drawLine(inner, outer, stroke);
    }
    c.drawCircle(center, w * 0.3, stroke);
    if (filled) {
      c.drawCircle(center, w * 0.13, fill);
    } else {
      c.drawCircle(center, w * 0.12, stroke);
    }
  }

  void _backArrow(Canvas c, Size s, Paint stroke) {
    final w = s.width;
    final path = Path()
      ..moveTo(w * 0.62, w * 0.26)
      ..lineTo(w * 0.38, w * 0.5)
      ..lineTo(w * 0.62, w * 0.74);
    c.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.filled != filled ||
      oldDelegate.color != color;
}
