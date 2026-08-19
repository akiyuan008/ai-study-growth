import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/app.dart';
import 'src/data/local/app_database.dart';
import 'src/design_system/growth_theme.dart';
import 'src/features/focus/focus_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // 数据库走 holder（云备份恢复时可重建实例）
  await cleanupStaleFocusSessions(AppDatabaseHolder.instance);
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AiStudyGrowthApp(),
    ),
  );
}
