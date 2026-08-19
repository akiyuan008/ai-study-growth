import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';

/// 首次启动引导：三屏讲清系统是什么、需要什么权限。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _page = 0;
  final _controller = PageController();

  static const _slides = [
    (
      Icons.menu_book_rounded,
      '把错题变成成长',
      '拍下错题，整理成你的专属题库。\n间隔复习帮你在忘记之前巩固，成长环记录每一点进步。',
    ),
    (
      Icons.auto_awesome_rounded,
      'AI 可选，核心离线',
      '不配置 AI 也能完整使用：拍题、复习、统计、备份。\n配置后 AI 帮你打知识点标签、推荐学习路径，可随时开关。',
    ),
    (
      Icons.cloud_sync_rounded,
      '数据只属于你',
      '无需注册账号。支持坚果云 / InfiniCLOUD / WebDAV 备份，\n换机时一键恢复，题库与图片完整带走。',
    ),
  ];

  Future<void> _finish() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return GrowthBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (icon, title, body) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(GrowthSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 96,
                          color: GrowthColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: GrowthSpacing.xl),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: GrowthSpacing.lg),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.8),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: GrowthMotion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? GrowthColors.primary
                          : GrowthColors.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(GrowthRadii.pill),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: GrowthSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GrowthSpacing.xl),
              child: GrowthButton(
                label: isLast ? '开始使用' : '继续',
                expanded: true,
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: GrowthMotion.base,
                      curve: GrowthMotion.standard,
                    );
                  }
                },
              ),
            ),
            if (isLast)
              TextButton(
                onPressed: () => context.push('/settings/backup?restore=1'),
                child: const Text('从云端恢复数据'),
              ),
            if (!isLast)
              TextButton(
                onPressed: _finish,
                child: const Text('跳过'),
              ),
            const SizedBox(height: GrowthSpacing.lg),
          ],
        ),
      ),
    ));
  }
}
