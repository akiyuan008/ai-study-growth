import 'package:flutter/material.dart';

import '../tokens.dart';
import 'growth_icons.dart';

/// 自定义页面头部（Prompt H：去 Material 化）。
/// 28/bold 大标题、透明背景、无 elevation、自定义线性返回箭头。
PreferredSizeWidget growthAppBar(
  BuildContext context, {
  required String title,
  bool showBack = false,
  VoidCallback? onBack,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    titleSpacing: showBack ? GrowthSpacing.sm : GrowthSpacing.lg,
    title: Row(
      children: [
        if (showBack)
          InkWell(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(GrowthRadii.icon),
            child: Padding(
              padding: const EdgeInsets.all(GrowthSpacing.sm),
              child: GrowthIcon(
                type: GrowthIconType.backArrow,
                size: 22,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        if (showBack) const SizedBox(width: GrowthSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: GrowthType.pageTitle.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
    actions: [
      ...?actions,
      const SizedBox(width: GrowthSpacing.md),
    ],
  );
}
