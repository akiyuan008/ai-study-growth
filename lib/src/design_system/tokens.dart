import 'package:flutter/material.dart';

/// Design Tokens —— 「极简心流 + 玻璃拟物」设计语言的唯一数值来源。
///
/// 规则：所有组件、页面只从这里取数值；
/// 业务代码禁止硬编码颜色、圆角、间距、时长。
abstract final class GrowthColors {
  // ---- 品牌主色 ----
  /// 种子蓝：系统主色，链接、选中、主按钮
  static const Color seed = Color(0xFF5B8DEF);

  // ---- 四能力色（成长引擎的视觉身份） ----
  /// 学习能力
  static const Color abilityLearning = Color(0xFF5B8DEF);

  /// 专注能力
  static const Color abilityFocus = Color(0xFFFF9F43);

  /// 坚持能力
  static const Color abilityPersistence = Color(0xFF3DBE7B);

  /// 恢复能力
  static const Color abilityRecovery = Color(0xFFA78BFA);

  // ---- 语义色 ----
  /// 生长绿：正向反馈 / 完成 / 上涨
  static const Color growth = Color(0xFF3DBE7B);

  /// 心流橙：当前行动 / 专注中
  static const Color flow = Color(0xFFFF9F43);

  /// 警示红：分心 / 下滑 / 危险操作
  static const Color caution = Color(0xFFEE6352);

  // ---- 表面 ----
  /// 纸感底色（浅色模式）
  static const Color surfaceLight = Color(0xFFF7F8FB);

  /// 深空底色（深色模式）
  static const Color surfaceDark = Color(0xFF12151C);

  /// 玻璃卡片着色（浅色模式）
  static const Color glassLight = Color(0xB8FFFFFF);

  /// 玻璃卡片着色（深色模式）
  static const Color glassDark = Color(0x8C232838);

  /// 玻璃描边高光
  static const Color glassBorderLight = Color(0x66FFFFFF);
  static const Color glassBorderDark = Color(0x29FFFFFF);
}

/// 字体规范
abstract final class GrowthType {
  /// 展示级大数字（心流倒计时）
  static const TextStyle display = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w200,
    letterSpacing: 2,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// 能量环中心的分数数字
  static const TextStyle ringScore = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// 圆角
abstract final class GrowthRadii {
  static const double chip = 12;
  static const double field = 16;
  static const double card = 24;
  static const double sheet = 32;
  static const double pill = 999;
}

/// 间距
abstract final class GrowthSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xxl = 64;
}

/// 玻璃拟物阴影与模糊参数
abstract final class GrowthGlass {
  /// 背景模糊强度
  static const double blurSigma = 18;

  /// 玻璃卡片投影（柔和、大扩散、低透明度）
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  /// 玻璃顶部内高光（模拟厚度）
  static const LinearGradient highlight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.35],
  );
}

/// 动效规范
abstract final class GrowthMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);

  /// 能量环 / 倒计时环的呼吸感时长
  static const Duration ring = Duration(milliseconds: 900);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}
