import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import '../features/design_gallery/presentation/design_gallery_page.dart';
import '../features/home/presentation/ai_provider_setup_page.dart';
import '../features/home/presentation/analysis_jobs_page.dart';
import '../features/home/presentation/capture_page.dart';
import '../features/home/presentation/main_shell_page.dart';
import '../features/home/presentation/notebook_page.dart';
import '../features/home/presentation/question_detail_page.dart';
import '../features/home/presentation/review_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/focus/presentation/focus_active_page.dart';
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
        path: '/notebook/:id',
        builder: (context, state) =>
            QuestionDetailPage(questionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const CapturePage(),
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
        path: '/design/gallery',
        builder: (context, state) => const DesignGalleryPage(),
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
    return MaterialApp.router(
      title: 'AI 学习成长系统',
      debugShowCheckedModeBanner: false,
      theme: buildGrowthTheme(Brightness.light),
      darkTheme: buildGrowthTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
