import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import '../features/design_gallery/presentation/design_gallery_page.dart';
import '../features/home/presentation/ai_provider_setup_page.dart';
import '../features/home/presentation/backup_settings_page.dart';
import '../features/home/presentation/cloud_sync_page.dart';
import '../features/capture/presentation/camera_capture_page.dart';
import '../features/capture/presentation/edit_screen_page.dart';
import '../features/capture/presentation/question_save_page.dart';
import '../core/bridge/scanner_bridge.dart' show CaptureSource;
import '../features/home/presentation/main_shell_page.dart';
import '../features/home/presentation/notebook_page.dart';
import '../features/home/presentation/question_detail_page.dart';
import '../features/home/presentation/review_page.dart';
import '../features/home/presentation/ai_call_log_page.dart';
import '../features/home/presentation/export_preview_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';

/// 路由配置（v15 终版）：
/// - 删除 /stats（统计独立页已删除）
/// - 删除成长页相关路由
/// - 保留：错题本/拍照/复习/设置/备份/AI/导出/画廊(debug)
final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final onboarded = prefs.getBool('onboarding_done') ?? false;
  return GoRouter(
    initialLocation: onboarded ? '/' : '/onboarding',
    observers: [SnackBarClearObserver()],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShellPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/notebook',
        builder: (context, state) => const NotebookListPage(),
      ),
      GoRoute(
        path: '/export/preview',
        builder: (context, state) => const ExportPreviewPage(),
      ),
      GoRoute(
        path: '/notebook/:id',
        builder: (context, state) =>
            QuestionDetailPage(questionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const CameraCapturePage(),
      ),
      GoRoute(
        path: '/capture/edit',
        builder: (context, state) => EditScreenPage(
          path: state.uri.queryParameters['path'] ?? '',
          source: CaptureSource.values.firstWhere(
            (s) => s.name == state.uri.queryParameters['source'],
            orElse: () => CaptureSource.camera,
          ),
          roi: _parseRoi(state.uri.queryParameters['roi']),
          returnCamera: state.uri.queryParameters['returnCamera'] == '1',
        ),
      ),
      GoRoute(
        path: '/capture/save',
        builder: (context, state) => QuestionSavePage(
          path: state.uri.queryParameters['path'] ?? '',
          source: CaptureSource.values.firstWhere(
            (s) => s.name == state.uri.queryParameters['source'],
            orElse: () => CaptureSource.camera,
          ),
          cropSource: state.uri.queryParameters['cropSource'] ?? 'original',
        ),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewSessionPage(),
      ),
      GoRoute(
        path: '/settings/ai-provider',
        builder: (context, state) => const AiProviderSetupPage(),
      ),
      GoRoute(
        path: '/settings/backup',
        builder: (context, state) => BackupSettingsPage(
          focusRestore: state.uri.queryParameters['restore'] == '1',
        ),
      ),
      GoRoute(
        path: '/settings/cloud-sync',
        builder: (context, state) => const CloudSyncPage(),
      ),
      GoRoute(
        path: '/settings/ai-call-log',
        builder: (context, state) => const AiCallLogPage(),
      ),
      GoRoute(
        // 画廊仅 debug 可见；release 包中该路由重定向回首页
        path: '/design/gallery',
        builder: (context, state) =>
            kDebugMode ? const DesignGalleryPage() : const MainShellPage(),
      ),
    ],
  );
});

class AiStudyGrowthApp extends ConsumerWidget {
  const AiStudyGrowthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // 系统栏随主题切 icon 亮暗
    final platform = MediaQuery.platformBrightnessOf(context);
    final effectiveDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platform == Brightness.dark);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: effectiveDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: GrowthColors.surfaceDarkBottom,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: GrowthColors.gray1,
            ),
      child: MaterialApp.router(
        scaffoldMessengerKey: appMessengerKey,
        title: '智析录',
        debugShowCheckedModeBanner: false,
        theme: buildGrowthTheme(Brightness.light),
        darkTheme: buildGrowthTheme(Brightness.dark),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}

/// 解析 roi=x,y,w,h
List<double>? _parseRoi(String? raw) {
  if (raw == null) return null;
  final parts = raw.split(',');
  if (parts.length != 4) return null;
  final vals = <double>[];
  for (final p in parts) {
    final v = double.tryParse(p);
    if (v == null) return null;
    vals.add(v);
  }
  return vals;
}

/// 路由级 SnackBar 清理：
/// toast 不得跨页残留——每次路由变更时清除当前 SnackBar。
class SnackBarClearObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _clearSnackBars();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _clearSnackBars();
  }

  @override
  void didPop(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    _clearSnackBars();
  }

  void _clearSnackBars() {
    final context = navigator?.context;
    if (context != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.clearSnackBars();
    }
  }
}
