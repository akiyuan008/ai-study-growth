import 'package:flutter/material.dart';

import '../tokens.dart';

/// 标签 Chip：知识点、短标签、状态标记
class GrowthChip extends StatelessWidget {
  const GrowthChip({
    super.key,
    required this.label,
    this.color,
    this.onTap,
    this.selected = false,
  });

  final String label;

  /// 主题色（默认种子蓝），实际渲染为该色的淡底 + 深色字
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final base = color ?? GrowthColors.seed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GrowthRadii.chip),
        child: AnimatedContainer(
          duration: GrowthMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: GrowthSpacing.sm + 4,
            vertical: GrowthSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? base : base.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(GrowthRadii.chip),
            border: Border.all(
              color: selected ? base : base.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : base,
            ),
          ),
        ),
      ),
    );
  }
}

/// 能力图例小点（能量环周边说明用）
class AbilityDot extends StatelessWidget {
  const AbilityDot({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: GrowthSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// 空状态占位（列表无数据时的温和提示）
class GrowthEmptyState extends StatelessWidget {
  const GrowthEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.spa_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GrowthSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 44, color: GrowthColors.seed.withValues(alpha: 0.5)),
          const SizedBox(height: GrowthSpacing.md),
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
