import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../growth/presentation/growth_home_page.dart';
import '../../learning/learning_providers.dart';
import 'notebook_page.dart';
import 'review_page.dart';

/// 主壳：错题本 / 复习 / 我的 + 中央拍题入口
class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const _ShellBody(),
      bottomNavigationBar: const _ShellNav(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GrowthColors.flow,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/capture'),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('拍题'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _ShellBody extends ConsumerWidget {
  const _ShellBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_shellTabProvider);
    return switch (tab) {
      0 => const _GrowthTab(),
      1 => const _NotebookTab(),
      2 => const _ReviewTabEntry(),
      _ => const _MeTab(),
    };
  }
}

final _shellTabProvider = StateProvider<int>((ref) => 0);

class _ShellNav extends ConsumerWidget {
  const _ShellNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_shellTabProvider);
    final dueCount = ref.watch(_dueCountProvider).valueOrNull ?? 0;

    return NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (i) =>
          ref.read(_shellTabProvider.notifier).state = i,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.spa_rounded),
          label: '成长',
        ),
        const NavigationDestination(
          icon: Icon(Icons.menu_book_rounded),
          label: '错题本',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: dueCount > 0,
            label: Text('$dueCount'),
            child: const Icon(Icons.replay_rounded),
          ),
          label: '复习',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_rounded),
          label: '我的',
        ),
      ],
    );
  }
}

final _dueCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(reviewRepositoryProvider).dueCount();
});

class _NotebookTab extends ConsumerWidget {
  const _NotebookTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NotebookListPage(embedded: true);
  }
}

class _GrowthTab extends ConsumerWidget {
  const _GrowthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GrowthHomePage(embedded: true);
  }
}

class _ReviewTabEntry extends ConsumerWidget {
  const _ReviewTabEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ReviewSessionPage(embedded: true);
  }
}

class _MeTab extends ConsumerStatefulWidget {
  const _MeTab();

  @override
  ConsumerState<_MeTab> createState() => _MeTabState();
}

class _MeTabState extends ConsumerState<_MeTab> {
  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(defaultAiConfigProvider);
    final configName = configAsync.valueOrNull?.name;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(GrowthSpacing.lg),
        children: [
          GrowthCard(
            onTap: () => context.push('/settings/ai-provider'),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_rounded, color: GrowthColors.seed),
                const SizedBox(width: GrowthSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI 服务商',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: GrowthSpacing.xs),
                      Text(
                        configName ?? '未配置 · 拍题解析需要',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: GrowthSpacing.md),
          GrowthCard(
            onTap: () => context.push('/analysis'),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: GrowthColors.flow),
                const SizedBox(width: GrowthSpacing.md),
                Expanded(
                  child: Text('解析任务队列',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: GrowthSpacing.md),
          GrowthCard(
            onTap: () => context.push('/design/gallery'),
            child: Row(
              children: [
                const Icon(Icons.palette_rounded,
                    color: GrowthColors.abilityRecovery),
                const SizedBox(width: GrowthSpacing.md),
                Expanded(
                  child: Text('设计系统画廊',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
