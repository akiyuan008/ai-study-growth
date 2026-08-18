import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens.dart';

/// 玻璃拟物卡片：背景模糊 + 半透明着色 + 高光描边 + 柔和投影。
/// 系统内所有信息容器的标准载体。
class GrowthCard extends StatelessWidget {
  const GrowthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GrowthSpacing.lg),
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GrowthRadii.card),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GrowthRadii.card),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: GrowthGlass.blurSigma,
                sigmaY: GrowthGlass.blurSigma,
              ),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: isLight
                      ? GrowthColors.glassLight
                      : GrowthColors.glassDark,
                  borderRadius: BorderRadius.circular(GrowthRadii.card),
                  border: Border.all(
                    color: isLight
                        ? GrowthColors.glassBorderLight
                        : GrowthColors.glassBorderDark,
                  ),
                  boxShadow: GrowthGlass.shadow,
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GrowthRadii.card),
                  gradient: GrowthGlass.highlight,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 区块标题（卡片内分组用）
class GrowthSectionHeader extends StatelessWidget {
  const GrowthSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
