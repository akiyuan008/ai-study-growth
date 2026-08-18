import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../focus/focus_providers.dart';

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
      Icons.spa_rounded,
      '欢迎',
      '这里不是任务清单，而是一个看着你变强的系统。\n错题本记录你学了什么，自律系统记录你有没有真学，成长引擎把它们变成看得见的四能力趋势。',
    ),
    (
      Icons.center_focus_strong_rounded,
      '专注时，MOSS 陪着你',
      '进入专注后，MOSS 伴读会感知你是否切出了 App：分心 1 分钟温和提醒，5 分钟锁屏干预。所有判定都在本机完成。',
    ),
    (
      Icons.lock_outline_rounded,
      '一个权限，换真实数据',
      '专注监控需要「使用情况访问」权限。没有它，分心就无法被记录，成长数据会失真。你随时可以在「我的 → AI 与权限」里查看。',
    ),
  ];

  Future<void> _finish() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;

    // 顺手引导使用情况访问权限
    final bridge = ref.read(monitorBridgeProvider);
    final granted = await bridge.isUsageAccessGranted();
    if (!mounted) return;
    if (!granted) {
      final goSettings = await showGrowthDialog(
        context: context,
        title: '现在就去授权？',
        message: '授权「使用情况访问」后，专注监控才能记录真实的分心与回归。',
        confirmLabel: '去授权',
        cancelLabel: '以后再说',
      );
      if (goSettings == true) {
        await bridge.openUsageAccessSettings();
      }
    }
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

    return Scaffold(
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
                          color: GrowthColors.seed.withValues(alpha: 0.7),
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
                          ? GrowthColors.seed
                          : GrowthColors.seed.withValues(alpha: 0.25),
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
            if (!isLast)
              TextButton(
                onPressed: _finish,
                child: const Text('跳过'),
              ),
            const SizedBox(height: GrowthSpacing.lg),
          ],
        ),
      ),
    );
  }
}
