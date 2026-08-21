import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/app.dart';
import 'src/core/cloud/supabase_config.dart';
import 'src/data/services/notification_service.dart';
import 'src/design_system/growth_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Supabase 云同步初始化（失败不阻塞启动，离线全功能可用）
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (_) {}
  // 单用户模式：后台自动登录共享账号（不阻塞启动，失败联网时重试）
  unawaited(_autoSignIn());
  // 通知服务初始化（复习提醒）
  unawaited(NotificationService.init());
  // 数据库走 holder（云备份恢复时可重建实例）
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AiStudyGrowthApp(),
    ),
  );
}

/// 启动后台自动登录（单用户共享账号）
Future<void> _autoSignIn() async {
  try {
    await Supabase.instance.client.auth.signInWithPassword(
      email: SupabaseConfig.sharedEmail,
      password: SupabaseConfig.sharedPassword,
    );
  } catch (_) {}
}
