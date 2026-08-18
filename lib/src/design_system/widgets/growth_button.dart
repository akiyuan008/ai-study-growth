import 'package:flutter/material.dart';

import '../tokens.dart';

enum GrowthButtonVariant { primary, secondary, ghost, danger }

/// 按钮体系（Prompt C 规范）：
/// - primary：靛蓝主色渐变胶囊（开始专注等主要行动）
/// - secondary：玻璃底
/// - ghost：无边框文字
/// - danger：警示
/// 橙色不出现在按钮上——它只属于拍题 FAB 与 streak 徽章。
class GrowthButton extends StatelessWidget {
  const GrowthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GrowthButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final GrowthButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final child = AnimatedOpacity(
      duration: GrowthMotion.fast,
      opacity: _enabled ? 1 : 0.45,
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  variant == GrowthButtonVariant.primary ||
                          variant == GrowthButtonVariant.danger
                      ? Colors.white
                      : GrowthColors.primary,
                ),
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: variant == GrowthButtonVariant.primary ||
                        variant == GrowthButtonVariant.danger
                    ? Colors.white
                    : variant == GrowthButtonVariant.secondary
                        ? scheme.onSurface
                        : GrowthColors.primary,
              ),
              const SizedBox(width: GrowthSpacing.sm),
            ],
            Text(
              label,
              style: TextStyle(
                color: variant == GrowthButtonVariant.primary ||
                        variant == GrowthButtonVariant.danger
                    ? Colors.white
                    : variant == GrowthButtonVariant.secondary
                        ? scheme.onSurface
                        : GrowthColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    final decoration = switch (variant) {
      GrowthButtonVariant.primary => BoxDecoration(
          gradient: GrowthGradients.primaryButton,
          borderRadius: BorderRadius.circular(GrowthRadii.pill),
          boxShadow: _enabled ? GrowthShadows.lift : null,
        ),
      GrowthButtonVariant.secondary => BoxDecoration(
          color: GrowthColors.glassLight,
          borderRadius: BorderRadius.circular(GrowthRadii.pill),
          border: Border.all(color: GrowthColors.glassBorderLight),
        ),
      GrowthButtonVariant.ghost => BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(GrowthRadii.pill),
        ),
      GrowthButtonVariant.danger => BoxDecoration(
          color: GrowthColors.caution,
          borderRadius: BorderRadius.circular(GrowthRadii.pill),
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(GrowthRadii.pill),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: GrowthSpacing.lg),
          decoration: decoration,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
