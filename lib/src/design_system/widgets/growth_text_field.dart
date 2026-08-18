import 'package:flutter/material.dart';

import '../tokens.dart';

/// 玻璃风格输入框
class GrowthTextField extends StatelessWidget {
  const GrowthTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.keyboardType,
  });

  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: GrowthSpacing.sm),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.38),
            ),
            filled: true,
            fillColor:
                isLight ? GrowthColors.glassLight : GrowthColors.glassDark,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: GrowthSpacing.md,
              vertical: GrowthSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GrowthRadii.field),
              borderSide: BorderSide(
                color: isLight
                    ? GrowthColors.glassBorderLight
                    : GrowthColors.glassBorderDark,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GrowthRadii.field),
              borderSide: BorderSide(
                color: isLight
                    ? GrowthColors.glassBorderLight
                    : GrowthColors.glassBorderDark,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GrowthRadii.field),
              borderSide:
                  const BorderSide(color: GrowthColors.primary, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
