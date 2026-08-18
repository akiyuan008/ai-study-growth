import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import '../features/design_gallery/presentation/design_gallery_page.dart';
import '../features/home/presentation/system_shell_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SystemShellPage(),
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
