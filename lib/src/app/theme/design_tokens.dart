import 'package:flutter/material.dart';

/// 设计令牌（Design Tokens）—— “极简心流 + 玻璃拟物”设计语言的种子。
/// P1 会扩展为完整组件库规范，P0 先定基调。
abstract final class GrowthTokens {
  // ---- 色彩：温暖、现代、沉浸、成长感 ----
  static const Color seed = Color(0xFF5B8DEF);

  /// 生长绿：能力上涨 / 正向反馈
  static const Color growth = Color(0xFF3DBE7B);

  /// 心流橙：专注中 / 当前行动
  static const Color flow = Color(0xFFFF9F43);

  /// 警示（恢复能力 / 分心）
  static const Color caution = Color(0xFFEE6352);

  /// 纸感底色（浅色模式）
  static const Color surfaceLight = Color(0xFFF7F8FB);

  /// 深空底色（深色模式）
  static const Color surfaceDark = Color(0xFF12151C);

  // ---- 圆角：玻璃拟物的大圆角 ----
  static const double radiusCard = 24;
  static const double radiusChip = 12;
  static const double radiusSheet = 32;

  // ---- 间距 ----
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 40;
}

/// 主题构建（P0 版本，P1 设计系统接管）
ThemeData buildGrowthTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: GrowthTokens.seed,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.light
        ? GrowthTokens.surfaceLight
        : GrowthTokens.surfaceDark,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GrowthTokens.radiusCard),
      ),
      color: scheme.surface
          .withValues(alpha: brightness == Brightness.light ? 0.72 : 0.55),
    ),
  );
}
