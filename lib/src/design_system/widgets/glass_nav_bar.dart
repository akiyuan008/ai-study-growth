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

/// GlassNavBar v2 —— 五 Tab 玻璃底栏（Part 1 IA v2）。
///
/// - 成长 | 错题本 | 复习 | 专注 | 设置
/// - 全局悬浮 FAB 已删除：拍题入口语境化（错题本右上/空状态 CTA/成长页 chip）
/// - 半透明玻璃 + 背景模糊，无 Material 默认灰底/elevation
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double barHeight = 62;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                  color: isLight
                      ? GrowthColors.glassLight
                      : GrowthColors.glassDark,
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
                    for (var i = 0; i < items.length; i++)
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
