import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import '../features/design_gallery/presentation/design_gallery_page.dart';
import '../features/home/presentation/ai_provider_setup_page.dart';
import '../features/home/presentation/app_whitelist_page.dart';
import '../features/home/presentation/analysis_jobs_page.dart';
import '../features/capture/presentation/camera_capture_page.dart';
import '../features/capture/presentation/edit_screen_page.dart';
import '../features/capture/presentation/question_save_page.dart';
import '../core/bridge/scanner_bridge.dart' show CaptureSource;
import '../features/home/presentation/main_shell_page.dart';
import '../features/home/presentation/notebook_page.dart';
import '../features/home/presentation/question_detail_page.dart';
import '../features/home/presentation/review_page.dart';
import '../features/home/presentation/stats_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/focus/presentation/focus_active_page.dart';
import '../features/focus/focus_providers.dart' show FocusMode;
import '../features/focus/presentation/focus_page.dart';
import '../features/focus/presentation/focus_result_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final onboarded = prefs.getBool('onboarding_done') ?? false;
  return GoRouter(
    initialLocation: onboarded ? '/' : '/onboarding',
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
        path: '/stats',
        builder: (context, state) => const StatsPage(),
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
        ),
      ),
      GoRoute(
        path: '/analysis',
        builder: (context, state) => AnalysisJobsPage(
          focusJobId: state.uri.queryParameters['focus'],
        ),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewSessionPage(),
      ),
      GoRoute(
        path: '/focus',
        builder: (context, state) => FocusPage(
          questionId: state.uri.queryParameters['questionId'],
          initialMode: state.uri.queryParameters['mode'] == 'abyss'
              ? FocusMode.abyss
              : null,
        ),
      ),
      GoRoute(
        path: '/focus/active',
        builder: (context, state) => const FocusActivePage(),
      ),
      GoRoute(
        path: '/focus/result',
        builder: (context, state) => const FocusResultPage(),
      ),
      GoRoute(
        path: '/settings/ai-provider',
        builder: (context, state) => const AiProviderSetupPage(),
      ),
      GoRoute(
        path: '/settings/app-whitelist',
        builder: (context, state) => const AppWhitelistPage(),
      ),
      GoRoute(
        // Prompt E：画廊仅 debug 可见；release 包中该路由重定向回首页，
        // 画廊内的演示控件（模拟涨落/心流演示）不会在 release 被触达
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
    return MaterialApp.router(
      title: 'AI 学习成长系统',
      debugShowCheckedModeBanner: false,
      theme: buildGrowthTheme(Brightness.light),
      // Prompt F4：深色模式本版冻结，固定浅色
      darkTheme: buildGrowthTheme(Brightness.light),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
