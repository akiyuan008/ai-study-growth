import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/bridge/behavior_bridge.dart';
import '../../../core/di/providers.dart';
import '../../../data/services/settings_service.dart';
import '../../../design_system/design_system.dart';
import '../../focus/focus_providers.dart' show monitorBridgeProvider;
import '../../focus/presentation/focus_home_page.dart';
import '../../growth/presentation/growth_home_page.dart';
import '../../learning/learning_providers.dart';
import 'notebook_page.dart';
import 'review_page.dart';

/// 主壳（Part 1 IA v2）：成长 | 错题本 | 复习 | 专注 | 设置
/// 全局悬浮 FAB 已删除，拍题入口语境化
/// Part 4.5：退后台 + 数据有变更 + WiFi（可配置允许流量）→ 自动备份
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _maybeAutoBackup();
    }
  }

  Future<void> _maybeAutoBackup() async {
    try {
      final backupState = ref.read(backupStateProvider);
      if (!backupState.isDirty) return;
      if (backupState.loadConfig() == null) return;

      final results = await Connectivity().checkConnectivity();
      final onWifi = results.contains(ConnectivityResult.wifi);
      final onCellular = results.contains(ConnectivityResult.mobile);
      if (!onWifi && !(onCellular && backupState.allowCellular)) return;

      await ref.read(backupServiceProvider).backupNow();
    } catch (_) {
      // 自动备份静默失败，不打扰用户
    }
  }

  @override
  Widget build(BuildContext context) {
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
          GlassNavItem(icon: GrowthIconType.target, label: '专注'),
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
      3 => const FocusHomePage(embedded: true),
      _ => const _MeTab(),
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

/// 我的页（Prompt E：设置分组版）
/// 排序：AI 服务商 → 解析任务队列 → 自律与监控 → 数据与关于
/// 设计系统画廊为 debug 隐藏入口：版本号连点 5 次进入
class _MeTab extends ConsumerStatefulWidget {
  const _MeTab();

  @override
  ConsumerState<_MeTab> createState() => _MeTabState();
}

class _MeTabState extends ConsumerState<_MeTab> {
  int _versionTaps = 0;

  Future<void> _onVersionTap() async {
    _versionTaps++;
    if (_versionTaps >= 5) {
      _versionTaps = 0;
      if (kDebugMode) {
        await context.push('/design/gallery');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正式版不含调试画廊')),
        );
      }
    }
  }

  Future<void> _exportBackup() async {
    try {
      final path = await DataExporter.exportToJson(ref.read(databaseProvider));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份完成：$path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('备份失败：$e')));
      }
    }
  }

  Future<void> _cleanImageCache() async {
    final freed = await ImageCacheCleaner.cleanCaptures();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '已清理 ${(freed / 1024 / 1024).toStringAsFixed(1)} MB 图片缓存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(defaultAiConfigProvider);
    final configName = configAsync.valueOrNull?.name;
    final monitorRunning = ref.watch(monitorRunningProvider);
    final bridge = ref.watch(monitorBridgeProvider);

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

            // ---- 云备份（Part 4） ----
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
            const SizedBox(height: GrowthSpacing.lg),

            _GroupLabel(label: '自律与监控'),
            GlassCard(
              child: Column(
                children: [
                  // 监控服务开关
                  Row(
                    children: [
                      const Icon(Icons.radar_rounded,
                          color: GrowthColors.primary),
                      const SizedBox(width: GrowthSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('监控服务',
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(
                              monitorRunning ? '运行中' : '已停止',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: monitorRunning,
                        activeThumbColor: GrowthColors.primary,
                        onChanged: (v) => _toggleMonitor(bridge, v),
                      ),
                    ],
                  ),
                  const _Divider(),
                  // 权限引导
                  _SettingRow(
                    icon: Icons.admin_panel_settings_rounded,
                    title: '使用统计权限',
                    subtitle: '分心判定的数据来源',
                    onTap: () => bridge.openUsageAccessSettings(),
                  ),
                  _SettingRow(
                    icon: Icons.layers_rounded,
                    title: '悬浮窗权限',
                    subtitle: '锁屏遮罩显示需要',
                    onTap: () => bridge.openOverlaySettings(),
                  ),
                  _SettingRow(
                    icon: Icons.notifications_rounded,
                    title: '通知权限',
                    subtitle: '提醒与前台服务通知',
                    onTap: () => bridge.openNotificationSettings(),
                  ),
                  const _Divider(),
                  // 深渊模式设置
                  _AbyssSettingRow(),
                  const _Divider(),
                  // App 分类管理（白名单）
                  _SettingRow(
                    icon: Icons.category_rounded,
                    title: 'App 分类管理',
                    subtitle: '白名单应用切换不算分心',
                    onTap: () => context.push('/settings/app-whitelist'),
                    showChevron: true,
                  ),
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
                      final version = snapshot.data?.version ?? '0.3.0';
                      return _SettingRow(
                        icon: Icons.info_outline_rounded,
                        title: '关于',
                        subtitle: 'AI 学习成长系统 v$version',
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

  Future<void> _toggleMonitor(MonitorBridge bridge, bool value) async {
    if (value) {
      final granted = await bridge.isUsageAccessGranted();
      if (!mounted) return;
      if (!granted) {
        final goSettings = await showGrowthDialog(
          context: context,
          title: '需要使用统计权限',
          message: '监控前台应用切换需要「使用情况访问」权限。',
          confirmLabel: '去授权',
        );
        if (goSettings == true) {
          await bridge.openUsageAccessSettings();
        }
        return;
      }
      await bridge.startMonitor();
      ref.read(monitorRunningProvider.notifier).state = true;
    } else {
      await bridge.stopMonitor();
      ref.read(monitorRunningProvider.notifier).state = false;
    }
  }
}

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
    this.showChevron = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

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
            if (showChevron) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

/// 深渊模式默认开关
class _AbyssSettingRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    return Row(
      children: [
        const Icon(Icons.waves_rounded, color: GrowthColors.primaryDeep),
        const SizedBox(width: GrowthSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('深渊模式为默认', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '更严格的干预：30 秒提醒 / 2 分钟锁屏',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          value: settings.abyssDefault,
          activeThumbColor: GrowthColors.primary,
          onChanged: (v) {
            ref.read(settingsServiceProvider).setAbyssDefault(v);
            ref.invalidate(settingsServiceProvider);
          },
        ),
      ],
    );
  }
}
