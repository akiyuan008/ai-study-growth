import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/di/providers.dart';
import '../../../data/services/settings_service.dart';
import '../../../design_system/design_system.dart';
import '../../growth/presentation/growth_home_page.dart';
import '../../learning/learning_providers.dart';
import 'notebook_page.dart';
import 'review_page.dart';

/// 主壳（v10 IA）：成长 | 错题本 | 复习 | 设置
/// 无全局 FAB，拍题入口语境化（错题本右上/空状态/成长页 NextStep）
class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_shellTabProvider);
    return Scaffold(
      body: const _ShellBody(),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: tab,
        onDestinationSelected: (i) =>
            ref.read(_shellTabProvider.notifier).state = i,
        items: const [
          GlassNavItem(icon: GrowthIconType.sprout, label: '成长'),
          GlassNavItem(icon: GrowthIconType.book, label: '错题本'),
          GlassNavItem(icon: GrowthIconType.replay, label: '复习'),
          GlassNavItem(icon: GrowthIconType.gear, label: '设置'),
        ],
      ),
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
      2 => const _ReviewTab(),
      _ => const _SettingsTab(),
    };
  }
}

final _shellTabProvider = StateProvider<int>((ref) => 0);

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

class _ReviewTab extends ConsumerWidget {
  const _ReviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ReviewSessionPage(embedded: true);
  }
}

/// 设置页。排序：AI 服务商 → 解析任务队列 → 云备份 → 数据与关于
class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab();

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  int _versionTaps = 0;

  Future<void> _onVersionTap() async {
    _versionTaps++;
    if (_versionTaps >= 5) {
      _versionTaps = 0;
      if (kDebugModeGuard()) {
        await context.push('/design/gallery');
      } else if (mounted) {
        // 被动提示一次（AppToast 自动去重）
        AppToast.info(context, '正式版不含调试画廊');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(defaultAiConfigProvider);
    final configName = configAsync.valueOrNull?.name;

    return Scaffold(
      appBar: growthAppBar(context, title: '设置'),
      body: GrowthBackground(
        child: ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            // ---- AI 服务商 ----
            GlassCard(
              onTap: () => context.push('/settings/ai-provider'),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_rounded,
                      color: GrowthColors.primary),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI 服务商',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: GrowthSpacing.xs),
                        Text(
                          configName ?? '未配置 · 不影响拍题与复习',
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

            // ---- 解析任务队列 ----
            GlassCard(
              onTap: () => context.push('/analysis'),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      color: GrowthColors.primary),
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

            // ---- 云备份 ----
            GlassCard(
              onTap: () => context.push('/settings/backup'),
              child: Row(
                children: [
                  const Icon(Icons.cloud_sync_rounded,
                      color: GrowthColors.primary),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('云备份',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: GrowthSpacing.xs),
                        Text(
                          '坚果云 / InfiniCLOUD / WebDAV / 本地导出',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.lg),

            _GroupLabel(label: '数据与关于'),
            GlassCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.backup_rounded,
                    title: '数据备份导出',
                    subtitle: '全库导出为 JSON 文件',
                    onTap: _exportBackup,
                  ),
                  _SettingRow(
                    icon: Icons.cleaning_services_rounded,
                    title: '图片缓存清理',
                    subtitle: '删除拍题图片与图片缓存',
                    onTap: _cleanImageCache,
                  ),
                  const _Divider(),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '0.6.0';
                      return _SettingRow(
                        icon: Icons.info_outline_rounded,
                        title: '关于',
                        subtitle: '跤错本 v$version',
                        onTap: _onVersionTap,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    try {
      final path = await _exportJson();
      if (mounted) {
        AppToast.success(context, '备份完成：$path');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '备份失败：$e');
      }
    }
  }

  Future<String> _exportJson() async {
    final db = ref.read(databaseProvider);
    return DataExporter.exportToJson(db);
  }

  Future<void> _cleanImageCache() async {
    final freed = await ImageCacheCleaner.cleanCaptures();
    if (mounted) {
      AppToast.success(
          context, '已清理 ${(freed / 1024 / 1024).toStringAsFixed(1)} MB 图片缓存');
    }
  }
}

/// debug 门禁：release 包画廊不可达
bool kDebugModeGuard() => kDebugMode;

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: GrowthSpacing.xs,
        bottom: GrowthSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GrowthSpacing.sm),
      child: Divider(
        height: 1,
        color: GrowthColors.gray2,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GrowthRadii.icon),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GrowthSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 22, color: GrowthColors.primary),
            const SizedBox(width: GrowthSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
