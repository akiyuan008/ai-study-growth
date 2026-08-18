import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'growth_button.dart';

/// 玻璃拟物对话框。确认返回 true，取消/点空白返回 null。
Future<bool?> showGrowthDialog({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  String confirmLabel = '确认',
  String cancelLabel = '取消',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(GrowthSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (message != null) ...[
                  const SizedBox(height: GrowthSpacing.sm),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (content != null) ...[
                  const SizedBox(height: GrowthSpacing.md),
                  content,
                ],
                const SizedBox(height: GrowthSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: GrowthButton(
                        label: cancelLabel,
                        variant: GrowthButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: GrowthSpacing.sm),
                    Expanded(
                      child: GrowthButton(
                        label: confirmLabel,
                        variant: destructive
                            ? GrowthButtonVariant.danger
                            : GrowthButtonVariant.primary,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 玻璃拟物底部抽屉（单核操作面板用）
Future<T?> showGrowthSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (context) {
      final isLight = Theme.of(context).brightness == Brightness.light;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GrowthRadii.sheet),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GrowthGlass.blurSigma,
            sigmaY: GrowthGlass.blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isLight ? GrowthColors.glassLight : GrowthColors.glassDark,
              border: Border.all(
                color: isLight
                    ? GrowthColors.glassBorderLight
                    : GrowthColors.glassBorderDark,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(GrowthRadii.sheet),
              ),
            ),
            padding: EdgeInsets.only(
              left: GrowthSpacing.lg,
              right: GrowthSpacing.lg,
              top: GrowthSpacing.md,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + GrowthSpacing.lg,
            ),
            child: builder(context),
          ),
        ),
      );
    },
  );
}
