import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens.dart';

/// 页面背景：低饱和渐变，衬出玻璃质感
class GrowthBackground extends StatelessWidget {
  const GrowthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isLight ? GrowthBackgrounds.light : GrowthBackgrounds.dark,
      ),
      child: child,
    );
  }
}

/// GlassCard —— 玻璃拟物卡片（Prompt C 规范）：
/// 半透明底 + BackdropFilter 模糊 + 1px 内描边高光 + 柔和投影。
/// 系统内所有信息容器的标准载体。
class GlassCard extends StatelessWidget {
  const GlassCard({
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
                  // 1px 内描边高光
                  border: Border.all(
                    width: GrowthGlass.innerBorderWidth,
                    color: isLight
                        ? GrowthColors.glassBorderLight
                        : GrowthColors.glassBorderDark,
                  ),
                  boxShadow: GrowthShadows.soft,
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

/// 兼容别名：旧代码中的 GrowthCard 一律指 GlassCard
typedef GrowthCard = GlassCard;
