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

/// GlassNavBar v4 —— 三 Tab + 中央相机键 dock（终版 IA）。
///
/// - 错题本 | 中央相机键 | 复习 | 设置（items 数量自适应，相机键居中）
/// - 相机键嵌入 dock，非悬浮
/// - 半透明玻璃 + 背景模糊，无 Material 默认灰底/elevation
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onCameraTap,
  });

  /// 常规项；onCameraTap 为 null 时不显示中央相机键
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onCameraTap;

  static const double barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navColor = isLight ? GrowthColors.glassLight : GrowthColors.glassDark;

    // 相机键居中：左侧 items.length ~/ 2 项，其余在右
    final hasCamera = onCameraTap != null;
    final leftCount = hasCamera ? items.length ~/ 2 : 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: barHeight,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: GrowthGlass.blurSigma,
                sigmaY: GrowthGlass.blurSigma,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: navColor,
                  border: Border(
                    top: BorderSide(
                      width: GrowthGlass.innerBorderWidth,
                      color: isLight
                          ? GrowthColors.glassBorderLight
                          : GrowthColors.glassBorderDark,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < leftCount; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: selectedIndex == i,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                    if (hasCamera) _CameraButton(onTap: onCameraTap!),
                    for (var i = leftCount; i < items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: selectedIndex == i,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          height: bottomPadding,
          color: navColor,
        ),
      ],
    );
  }
}

/// 嵌入式相机按钮 —— 托架切口设计，视觉与 dock 一体
class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GrowthColors.primary,
                GrowthColors.primary.withValues(alpha: 0.82),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: GrowthColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          width: 48,
          height: 48,
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
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
              size: 22,
              filled: selected,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
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
