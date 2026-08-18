import 'package:ai_study_growth/src/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildGrowthTheme', () {
    test('浅色模式使用纸感底色', () {
      final theme = buildGrowthTheme(Brightness.light);
      expect(theme.scaffoldBackgroundColor, GrowthColors.gray1);
    });

    test('深色模式使用深空底色', () {
      final theme = buildGrowthTheme(Brightness.dark);
      expect(theme.scaffoldBackgroundColor, GrowthColors.surfaceDark);
    });

    test('卡片圆角来自令牌', () {
      final theme = buildGrowthTheme(Brightness.light);
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(
        (shape.borderRadius as BorderRadius).topLeft.x,
        GrowthRadii.card,
      );
    });
  });

  group('ThemeModeNotifier（深色冻结，Prompt F4）', () {
    test('固定浅色：set(dark) 也落回浅色并持久化', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeModeNotifier(prefs);

      expect(notifier.state, ThemeMode.light);

      await notifier.set(ThemeMode.dark);
      expect(notifier.state, ThemeMode.light);

      final reloaded = ThemeModeNotifier(prefs);
      expect(reloaded.state, ThemeMode.light);
    });
  });

  group('tokens 一致性', () {
    test('四能力色互不相同', () {
      final colors = {
        GrowthColors.abilityLearning,
        GrowthColors.abilityFocus,
        GrowthColors.abilityPersistence,
        GrowthColors.abilityRecovery,
      };
      expect(colors.length, 4);
    });
  });
}
