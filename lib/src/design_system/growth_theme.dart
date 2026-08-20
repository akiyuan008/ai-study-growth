import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tokens.dart';

/// 主题管理器（主题三态：跟随系统/浅色/深色，默认跟随系统）。
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'growth.theme_mode';

  static ThemeMode _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }

  Future<void> toggleLightDark() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('main() 中异步初始化后 override');
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

/// 从 Design Tokens 构建 ThemeData（app_theme）
ThemeData buildGrowthTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: GrowthColors.primary,
    brightness: brightness,
  );

  final surface = isLight ? GrowthColors.gray1 : GrowthColors.surfaceDark;
  final onSurface = isLight ? GrowthColors.gray6 : GrowthColors.onSurfaceDark;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(
      surface: surface,
      onSurface: onSurface,
      primary: GrowthColors.primary,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
          headlineMedium: GrowthType.pageTitle.copyWith(color: onSurface),
          titleLarge: GrowthType.cardTitle.copyWith(color: onSurface),
          bodyMedium: GrowthType.body.copyWith(color: onSurface),
          bodySmall: GrowthType.caption.copyWith(
            color: isLight
                ? GrowthColors.gray5
                : onSurface.withValues(alpha: 0.62),
          ),
        ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GrowthRadii.card),
      ),
      color: isLight ? GrowthColors.glassLight : GrowthColors.glassDark,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor:
          isLight ? GrowthColors.glassLight : GrowthColors.glassDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GrowthRadii.card),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GrowthRadii.icon),
      ),
    ),
  );
}

/// 调试用：导出当前 tokens 摘要（开发面板）
String describeTokens() => jsonEncode({
      'colors': {
        'primary': GrowthColors.primary.toARGB32().toRadixString(16),
        'actionAccent': GrowthColors.actionAccent.toARGB32().toRadixString(16),
      },
      'glass': {'blurSigma': GrowthGlass.blurSigma},
      'motion': {'base': GrowthMotion.base.inMilliseconds},
    });
