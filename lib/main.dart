import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/app.dart';
import 'src/core/di/providers.dart';
import 'src/data/local/app_database.dart';
import 'src/design_system/growth_theme.dart';
import 'src/features/focus/focus_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // 单一数据库实例：启动恢复 + 全局注入
  final db = openAppDatabase();
  await cleanupStaleFocusSessions(db);
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
      child: const AiStudyGrowthApp(),
    ),
  );
}
