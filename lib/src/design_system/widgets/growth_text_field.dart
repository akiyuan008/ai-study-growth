import 'package:flutter/material.dart';

import '../tokens.dart';

/// 玻璃风格输入框。
/// 支持：密文模式 + 可见性切换（Prompt G7）、灰色 helper 校验文本（Prompt G6）。
class GrowthTextField extends StatefulWidget {
  const GrowthTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.helper,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.keyboardType,
    this.obscure = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final String? label;

  /// 灰色辅助/校验文本（指明缺哪一项）
  final String? helper;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;

  /// 密文输入（API Key），自动附带可见性切换眼睛
  final bool obscure;

  @override
  State<GrowthTextField> createState() => _GrowthTextFieldState();
}

class _GrowthTextFieldState extends State<GrowthTextField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final showEye = widget.obscure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: GrowthSpacing.sm),
        ],
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          maxLines: showEye ? 1 : widget.maxLines,
          obscureText: showEye && !_visible,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          keyboardType: widget.keyboardType,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hint,
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
            suffixIcon: showEye
                ? IconButton(
                    icon: Icon(
                      _visible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: GrowthColors.gray4,
                    ),
                    onPressed: () => setState(() => _visible = !_visible),
                  )
                : null,
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
        if (widget.helper != null && widget.helper!.isNotEmpty) ...[
          const SizedBox(height: GrowthSpacing.xs),
          Text(
            widget.helper!,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: GrowthColors.gray5,
            ),
          ),
        ],
      ],
    );
  }
}
