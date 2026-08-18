import 'package:flutter/material.dart';

import '../tokens.dart';

/// 品牌空状态插画：一本摊开的线稿书，中间长出一株嫩芽。
/// 替换通用 Material 图标，与「生长」品牌心智一致（Prompt D3）。
class GrowthSproutIllustration extends StatelessWidget {
  const GrowthSproutIllustration({
    super.key,
    this.size = 120,
    this.color,
    this.sproutColor,
  });

  final double size;
  final Color? color;
  final Color? sproutColor;

  @override
  Widget build(BuildContext context) {
    final base = color ?? GrowthColors.primary.withValues(alpha: 0.55);
    final leaf = sproutColor ?? GrowthColors.success.withValues(alpha: 0.8);
    return CustomPaint(
      size: Size.square(size),
      painter: _SproutPainter(base: base, leaf: leaf),
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({required this.base, required this.leaf});

  final Color base;
  final Color leaf;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = base;

    // ---- 摊开的书（下半部分） ----
    final bookTop = h * 0.62;
    final cx = w / 2;

    // 左页
    final leftPage = Path()
      ..moveTo(cx, bookTop + h * 0.06)
      ..cubicTo(
        cx - w * 0.18,
        bookTop - h * 0.02,
        cx - w * 0.34,
        bookTop,
        cx - w * 0.42,
        bookTop + h * 0.06,
      )
      ..lineTo(cx - w * 0.42, bookTop + h * 0.22)
      ..cubicTo(
        cx - w * 0.34,
        bookTop + h * 0.16,
        cx - w * 0.18,
        bookTop + h * 0.14,
        cx,
        bookTop + h * 0.22,
      );
    canvas.drawPath(leftPage, stroke);

    // 右页（镜像）
    final rightPage = Path()
      ..moveTo(cx, bookTop + h * 0.06)
      ..cubicTo(
        cx + w * 0.18,
        bookTop - h * 0.02,
        cx + w * 0.34,
        bookTop,
        cx + w * 0.42,
        bookTop + h * 0.06,
      )
      ..lineTo(cx + w * 0.42, bookTop + h * 0.22)
      ..cubicTo(
        cx + w * 0.34,
        bookTop + h * 0.16,
        cx + w * 0.18,
        bookTop + h * 0.14,
        cx,
        bookTop + h * 0.22,
      );
    canvas.drawPath(rightPage, stroke);

    // 中缝
    canvas.drawLine(
      Offset(cx, bookTop + h * 0.06),
      Offset(cx, bookTop + h * 0.22),
      stroke..color = base.withValues(alpha: 0.5),
    );

    // 左页内的文字线
    final lineStroke = stroke
      ..color = base.withValues(alpha: 0.35)
      ..strokeWidth = w * 0.02;
    canvas.drawLine(
      Offset(cx - w * 0.30, bookTop + h * 0.10),
      Offset(cx - w * 0.14, bookTop + h * 0.085),
      lineStroke,
    );
    canvas.drawLine(
      Offset(cx + w * 0.14, bookTop + h * 0.085),
      Offset(cx + w * 0.30, bookTop + h * 0.10),
      lineStroke,
    );

    // ---- 嫩芽（从书中长出） ----
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..color = leaf;

    // 茎：从中缝向上，微微弯曲
    final stem = Path()
      ..moveTo(cx, bookTop + h * 0.05)
      ..cubicTo(
        cx - w * 0.02,
        bookTop - h * 0.10,
        cx + w * 0.03,
        bookTop - h * 0.20,
        cx,
        bookTop - h * 0.32,
      );
    canvas.drawPath(stem, stemPaint);

    // 左叶
    final leafTop = bookTop - h * 0.20;
    final leftLeaf = Path()
      ..moveTo(cx - w * 0.005, leafTop + h * 0.06)
      ..cubicTo(
        cx - w * 0.16,
        leafTop + h * 0.02,
        cx - w * 0.18,
        leafTop - h * 0.10,
        cx - w * 0.10,
        leafTop - h * 0.13,
      )
      ..cubicTo(
        cx - w * 0.03,
        leafTop - h * 0.10,
        cx - w * 0.01,
        leafTop - h * 0.02,
        cx - w * 0.005,
        leafTop + h * 0.06,
      );
    canvas.drawPath(
      leftLeaf,
      Paint()..color = leaf.withValues(alpha: 0.22),
    );
    canvas.drawPath(leftLeaf, stemPaint..strokeWidth = w * 0.022);

    // 右叶（略高）
    final rightLeaf = Path()
      ..moveTo(cx + w * 0.005, leafTop - h * 0.02)
      ..cubicTo(
        cx + w * 0.14,
        leafTop - h * 0.05,
        cx + w * 0.17,
        leafTop - h * 0.17,
        cx + w * 0.09,
        leafTop - h * 0.21,
      )
      ..cubicTo(
        cx + w * 0.02,
        leafTop - h * 0.17,
        cx + w * 0.01,
        leafTop - h * 0.09,
        cx + w * 0.005,
        leafTop - h * 0.02,
      );
    canvas.drawPath(
      rightLeaf,
      Paint()..color = leaf.withValues(alpha: 0.22),
    );
    canvas.drawPath(rightLeaf, stemPaint);

    // 芽尖小点
    canvas.drawCircle(
      Offset(cx, bookTop - h * 0.33),
      w * 0.02,
      Paint()..color = leaf,
    );
  }

  @override
  bool shouldRepaint(covariant _SproutPainter oldDelegate) =>
      oldDelegate.base != base || oldDelegate.leaf != leaf;
}

/// 通用空状态（插画版）：书本 + 嫩芽 + 两行文案
class GrowthEmptyState extends StatelessWidget {
  const GrowthEmptyState({
    super.key,
    required this.message,
    this.illustrationSize = 110,
  });

  final String message;
  final double illustrationSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: GrowthSpacing.xl,
        // Prompt D1：文案 24px 水平内边距，避免贴边裁切
        horizontal: GrowthSpacing.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GrowthSproutIllustration(size: illustrationSize),
          const SizedBox(height: GrowthSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
