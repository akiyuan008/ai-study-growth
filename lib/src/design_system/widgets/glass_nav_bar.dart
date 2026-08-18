import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'growth_icons.dart';

/// 底部导航项定义
class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});

  final GrowthIconType icon;
  final String label;
}

/// GlassNavBar —— 玻璃拟物底栏 + 中央托架切口 FAB（Prompt H）。
///
/// - 半透明玻璃材质 + 背景模糊，无 Material 默认灰底/elevation
/// - 中央圆形托架切口（notch），拍题 FAB 嵌入其中，上浮 ≤12px
/// - 切口边缘 1px 高光描边；FAB 橙色渐变 + 阴影
/// - 导航栏与 FAB 视觉读作一个组件
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onCenterTap,
    this.centerLabel = '拍题',
  });

  /// 左二 + 右二，共 4 项（中央为 FAB）
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onCenterTap;
  final String centerLabel;

  static const double barHeight = 64;
  static const double fabSize = 60;
  static const double notchRadius = 38;

  /// FAB 相对切口中心的上浮量（≤12px）
  static const double fabLift = 10;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final w = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 左右各 2 个 Tab
    final leftItems = items.sublist(0, 2);
    final rightItems = items.sublist(2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: barHeight + fabLift,
          width: w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ---- 玻璃栏（带切口） ----
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: ClipPath(
                  clipper: _NotchClipper(notchRadius: notchRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: GrowthGlass.blurSigma,
                      sigmaY: GrowthGlass.blurSigma,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLight
                            ? GrowthColors.glassLight
                            : GrowthColors.glassDark,
                      ),
                    ),
                  ),
                ),
              ),
              // ---- 切口 + 顶边 1px 高光描边 ----
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _NotchBorderPainter(
                      notchRadius: notchRadius,
                      color: isLight
                          ? GrowthColors.glassBorderLight
                          : GrowthColors.glassBorderDark,
                    ),
                  ),
                ),
              ),
              // ---- Tab 项 ----
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < 2; i++)
                      Expanded(
                        child: _NavButton(
                          item: leftItems[i],
                          selected: selectedIndex == i,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                    // 中央留白（FAB 区）
                    SizedBox(width: notchRadius * 2 + 16),
                    for (var i = 0; i < 2; i++)
                      Expanded(
                        child: _NavButton(
                          item: rightItems[i],
                          selected: selectedIndex == i + 2,
                          onTap: () => onDestinationSelected(i + 2),
                        ),
                      ),
                  ],
                ),
              ),
              // ---- 中央 FAB：嵌入切口，上浮 fabLift ----
              Positioned(
                left: w / 2 - fabSize / 2,
                // FAB 顶边高出栏顶 fabLift（≤12px），其余嵌入切口
                bottom: barHeight + fabLift - fabSize,
                child: _CenterFab(
                  size: fabSize,
                  label: centerLabel,
                  onTap: onCenterTap,
                ),
              ),
            ],
          ),
        ),
        // 安全区
        Container(
          height: bottomPadding,
          color: isLight ? GrowthColors.glassLight : GrowthColors.glassDark,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GrowthColors.primary : GrowthColors.gray4;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GrowthIcon(
              type: item.icon,
              size: 23,
              filled: selected,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({
    required this.size,
    required this.label,
    required this.onTap,
  });

  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GrowthRadii.pill),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFB25E), GrowthColors.actionAccent],
            ),
            border: Border.all(
              width: GrowthGlass.innerBorderWidth,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59FF9F43),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GrowthIcon(
                type: GrowthIconType.camera,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 托架切口裁剪
class _NotchClipper extends CustomClipper<Path> {
  _NotchClipper({required this.notchRadius});

  final double notchRadius;

  @override
  Path getClip(Size size) {
    final cx = size.width / 2;
    final r = notchRadius;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(cx - r - 8, 0)
      // 切口：从左肩绕到右肩（向下凹的半圆）
      ..cubicTo(cx - r + 6, 0, cx - r, r * 0.45, cx - r + 4, r * 0.75)
      ..cubicTo(
          cx - r + 12, r * 1.25, cx + r - 12, r * 1.25, cx + r - 4, r * 0.75)
      ..cubicTo(cx + r, r * 0.45, cx + r - 6, 0, cx + r + 8, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _NotchClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius;
}

/// 顶边 + 切口 1px 高光描边
class _NotchBorderPainter extends CustomPainter {
  _NotchBorderPainter({required this.notchRadius, required this.color});

  final double notchRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r = notchRadius;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = GrowthGlass.innerBorderWidth
      ..color = color;

    // 顶边左段
    canvas.drawLine(const Offset(0, 0.5), Offset(cx - r - 8, 0.5), paint);
    // 顶边右段
    canvas.drawLine(Offset(cx + r + 8, 0.5), Offset(size.width, 0.5), paint);
    // 切口弧
    final notch = Path()
      ..moveTo(cx - r - 8, 0)
      ..cubicTo(cx - r + 6, 0, cx - r, r * 0.45, cx - r + 4, r * 0.75)
      ..cubicTo(
          cx - r + 12, r * 1.25, cx + r - 12, r * 1.25, cx + r - 4, r * 0.75)
      ..cubicTo(cx + r, r * 0.45, cx + r - 6, 0, cx + r + 8, 0);
    canvas.drawPath(notch, paint);
  }

  @override
  bool shouldRepaint(covariant _NotchBorderPainter oldDelegate) =>
      oldDelegate.notchRadius != notchRadius || oldDelegate.color != color;
}
