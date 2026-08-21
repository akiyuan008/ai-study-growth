import 'package:flutter/material.dart';

/// Design Tokens —— 「极简心流 + 玻璃拟物」设计语言的唯一数值来源。
///
/// 色彩纪律（Prompt C 规范）：
/// - 品牌主色 = 靛蓝/墨蓝系，承载系统身份与主要交互
/// - 暖橙 = 行动强调色，只允许出现在拍题 FAB 与 streak 徽章
/// - 四能力色属于数据可视化语义色，不受上述限制
abstract final class GrowthColors {
  // ---- 品牌主色：靛蓝/墨蓝系 ----
  /// 靛蓝主色：主按钮、选中态、链接、主图标
  static const Color primary = Color(0xFF4353C2);

  /// 深靛蓝：主按钮渐变收尾、标题强调
  static const Color primaryDeep = Color(0xFF28328C);

  /// 墨蓝：深色模式下的强调底色
  static const Color inkBlue = Color(0xFF1B2252);

  // ---- 行动强调色：仅限拍题 FAB 与 streak 徽章 ----
  static const Color actionAccent = Color(0xFFFF9F43);

  // ---- 语义色 ----
  static const Color success = Color(0xFF3DBE7B);
  static const Color caution = Color(0xFFEE6352);

  /// 别名（Prompt F3 令牌治理）：业务代码一律用语义别名，
  /// 禁止直接引用重复色值。
  static const Color danger = caution;
  static const Color warning = caution;
  static const Color error = caution;

  // ---- 四能力色（数据可视化语义色，全部走别名映射） ----
  /// 学习 = 主色靛蓝
  static const Color learning = primary;
  static const Color abilityLearning = primary;

  /// 专注 = 行动强调橙
  static const Color focus = actionAccent;
  static const Color abilityFocus = actionAccent;

  /// 坚持 = 成功绿
  static const Color persistence = success;
  static const Color abilityPersistence = success;

  /// 恢复 = 紫（独立色相，无重复值）
  static const Color abilityRecovery = Color(0xFFA78BFA);

  // ---- 中性灰阶（6 级） ----
  /// 页面底色（浅色）
  static const Color gray1 = Color(0xFFF7F8FB);
  static const Color gray2 = Color(0xFFEDEFF4);
  static const Color gray3 = Color(0xFFD5D9E2);
  static const Color gray4 = Color(0xFFA6ADBF);
  static const Color gray5 = Color(0xFF6B7280);

  /// 近黑（浅色模式文字 / 深色模式底色）
  static const Color gray6 = Color(0xFF23272F);

  /// 次要文字色（自适应）：深色模式用 onSurfaceDarkDim，保证对比度≥4.5:1
  static Color muted(bool isLight) => isLight ? gray5 : onSurfaceDarkDim;

  /// 深空底色（深色模式，深灰靛渐变两端）
  static const Color surfaceDarkTop = Color(0xFF12141C);
  static const Color surfaceDarkBottom = Color(0xFF1A1D29);
  static const Color surfaceDark = Color(0xFF12141C);

  /// 深色模式表面亮度层级（暗色层级用亮度表达，不用阴影）
  static const Color surfaceDarkRaised = Color(0xFF232636);

  // ---- 深色模式可读变体（主色提亮、强调与能力色暗色变体） ----
  static const Color primaryDark = Color(0xFF7C8CF8);
  static const Color successDark = Color(0xFF5ED69A);
  static const Color actionAccentDark = Color(0xFFFFB25E);
  static const Color warningDark = Color(0xFFFF8A7A);
  static const Color learningDark = Color(0xFF8FA8FF);
  static const Color persistenceDark = Color(0xFF5ED69A);
  static const Color recoveryDark = Color(0xFFBCA6FF);

  /// 深色模式文本（对比度 ≥4.5:1）
  static const Color onSurfaceDark = Color(0xFFEDF0F7);
  static const Color onSurfaceDarkDim = Color(0xFFA8AFC4);

  /// 玻璃拟物（深色：白 8-12% 透明）
  static const Color glassDarkFill = Color(0x1AFFFFFF);
  static const Color glassDarkBorder = Color(0x29FFFFFF);

  /// 能量环轨道色
  static const Color ringTrackLight = Color(0x14101828);
  static const Color ringTrackDark = Color(0x29FFFFFF);

  /// 相机腔体遮罩（相机页例外恒定暗色）
  static const Color cameraOverlayTop = Color(0xCC000000);
  static const Color cameraOverlayBottom = Color(0xE6000000);

  /// 主题自适应：浅色令牌 → 深色可读变体
  static Color adapt(Color c, bool isLight) {
    if (isLight) return c;
    return switch (c) {
      primary => primaryDark,
      success => successDark,
      actionAccent => actionAccentDark,
      warning => warningDark,
      learning => learningDark,
      abilityLearning => learningDark,
      abilityPersistence => persistenceDark,
      abilityRecovery => recoveryDark,
      gray5 => onSurfaceDarkDim,
      gray4 => onSurfaceDarkDim,
      _ => c,
    };
  }

  // ---- 玻璃拟物 ----
  static const Color glassLight = Color(0xB8FFFFFF);
  static const Color glassDark = Color(0x8C232838);
  static const Color glassBorderLight = Color(0x66FFFFFF);
  static const Color glassBorderDark = Color(0x29FFFFFF);
}

/// 排版阶（Prompt C 规范）
abstract final class GrowthType {
  /// 页标题 28/bold
  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// 卡片标题 20/semibold
  static const TextStyle cardTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// 正文 15，行高 1.5
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 辅助 13，行高 1.5
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 展示级大数字（心流倒计时）
  static const TextStyle display = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w200,
    letterSpacing: 2,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.1,
  );

  /// 能量环中心的定性文案
  static const TextStyle ringCenter = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
}

/// 圆角阶（Prompt C 规范）
abstract final class GrowthRadii {
  /// 图标容器
  static const double icon = 12;

  /// 输入框
  static const double field = 16;

  /// 卡片
  static const double card = 24;

  /// 底部抽屉
  static const double sheet = 32;

  /// 按钮全圆角（胶囊）
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

/// 阴影阶（2 级）
abstract final class GrowthShadows {
  /// 一级：玻璃卡片常态（柔和贴地）
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  /// 二级：主按钮/悬浮元素（带主色倾向的抬升感）
  static const List<BoxShadow> lift = [
    BoxShadow(
      color: Color(0x404353C2),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}

/// 玻璃拟物参数
abstract final class GrowthGlass {
  /// 背景模糊强度
  static const double blurSigma = 18;

  /// 1px 内描边高光宽度
  static const double innerBorderWidth = 1;

  /// 玻璃顶部内高光（模拟厚度）
  static const LinearGradient highlight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.35],
  );
}

/// 页面背景：低饱和对角渐变（左上浅靛 → 右下灰白），衬出玻璃质感
abstract final class GrowthBackgrounds {
  static const LinearGradient light = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEEF1FB), Color(0xFFF6F7F9)],
  );

  /// 深色冻结期内仅作占位（与 light 相同）
  static const LinearGradient dark = light;
}

/// 主按钮渐变（靛蓝系胶囊）
abstract final class GrowthGradients {
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GrowthColors.primary, GrowthColors.primaryDeep],
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
