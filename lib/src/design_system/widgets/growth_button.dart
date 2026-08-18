import 'package:flutter/material.dart';

import '../tokens.dart';

enum GrowthButtonVariant { primary, secondary, ghost, danger }

/// 主按钮。primary 实心、secondary 玻璃、ghost 无边框、danger 警示。
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

    final (Color background, Color foreground, Border? border) =
        switch (variant) {
      GrowthButtonVariant.primary => (GrowthColors.seed, Colors.white, null),
      GrowthButtonVariant.secondary => (
          GrowthColors.glassLight,
          scheme.onSurface,
          Border.all(color: GrowthColors.glassBorderLight)
        ),
      GrowthButtonVariant.ghost => (
          Colors.transparent,
          GrowthColors.seed,
          null
        ),
      GrowthButtonVariant.danger => (GrowthColors.caution, Colors.white, null),
    };

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
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: GrowthSpacing.sm),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(GrowthRadii.pill),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: GrowthSpacing.lg),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(GrowthRadii.pill),
            border: border,
            boxShadow: variant == GrowthButtonVariant.primary && _enabled
                ? [
                    BoxShadow(
                      color: GrowthColors.seed.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
