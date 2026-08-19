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

/// GlassNavBar v3 —— 五槽 dock + 中央相机键（Part 2 v13）。
///
/// - 成长 | 错题本 | 中央相机键 | 复习 | 设置
/// - 相机键嵌入 dock（托架切口），非悬浮
/// - 半透明玻璃 + 背景模糊，无 Material 默认灰底/elevation
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onCameraTap,
  });

  /// 4 个常规项（成长/错题本/复习/设置），相机键在中间固定
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onCameraTap;

  static const double barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navColor = isLight ? GrowthColors.glassLight : GrowthColors.glassDark;

    // items[0]=成长, items[1]=错题本, items[2]=复习, items[3]=设置
    // dock 布局: 成长 | 错题本 | [相机键] | 复习 | 设置
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
                    // 成长 (index 0)
                    Expanded(
                      child: _NavButton(
                        item: items[0],
                        selected: selectedIndex == 0,
                        onTap: () => onDestinationSelected(0),
                      ),
                    ),
                    // 错题本 (index 1)
                    Expanded(
                      child: _NavButton(
                        item: items[1],
                        selected: selectedIndex == 1,
                        onTap: () => onDestinationSelected(1),
                      ),
                    ),
                    // 中央相机键 (嵌入 dock，托架切口)
                    _CameraButton(onTap: onCameraTap),
                    // 复习 (index 2 in provider = 3rd tab)
                    Expanded(
                      child: _NavButton(
                        item: items[2],
                        selected: selectedIndex == 2,
                        onTap: () => onDestinationSelected(2),
                      ),
                    ),
                    // 设置 (index 3 in provider = 4th tab)
                    Expanded(
                      child: _NavButton(
                        item: items[3],
                        selected: selectedIndex == 3,
                        onTap: () => onDestinationSelected(3),
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
