import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/di/providers.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/repositories/exam_bank_repository.dart';
import '../../../data/services/settings_service.dart';
import '../../../design_system/design_system.dart';
import '../../capture/presentation/camera_capture_page.dart';
import '../../learning/learning_providers.dart';
import 'notebook_page.dart';
import 'review_page.dart';

/// 主壳（v15 终版）：错题本 | 📷中央相机键 | 复习 | 设置
/// 三 Tab + 底栏中央凸起相机按钮
class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);
    return _ShellLifecycle(
      child: Scaffold(
        body: const _ShellBody(),
        bottomNavigationBar: GlassNavBar(
          selectedIndex: tab,
          onDestinationSelected: (i) =>
              ref.read(shellTabProvider.notifier).state = i,
          items: const [
            GlassNavItem(icon: GrowthIconType.camera, label: '拍照'),
            GlassNavItem(icon: GrowthIconType.book, label: '错题本'),
            GlassNavItem(icon: GrowthIconType.replay, label: '复习'),
            GlassNavItem(icon: GrowthIconType.gear, label: '设置'),
          ],
        ),
      ),
    );
  }
}

/// 前台恢复时自动补同步（静默，失败不打扰）
class _ShellLifecycle extends ConsumerStatefulWidget {
  const _ShellLifecycle({required this.child});

  final Widget child;

  @override
  ConsumerState<_ShellLifecycle> createState() => _ShellLifecycleState();
}

class _ShellLifecycleState extends ConsumerState<_ShellLifecycle>
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
    if (state == AppLifecycleState.resumed) {
      // 回前台：云同步补同步
      unawaited(ref.read(cloudSyncProvider).autoSync());
    } else if (state == AppLifecycleState.paused) {
      // 退后台：有脏数据且满足网络策略时自动备份
      unawaited(ref.read(backupServiceProvider).maybeAutoBackup());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ShellBody extends ConsumerWidget {
  const _ShellBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);
    return switch (tab) {
      0 => const _CameraTab(),
      1 => const _NotebookTab(),
      2 => const _ReviewTab(),
      _ => const _SettingsTab(),
    };
  }
}

/// 主壳 Tab：0 拍照 / 1 错题本 / 2 复习 / 3 设置
final shellTabProvider = StateProvider<int>((ref) => 0);

class _CameraTab extends ConsumerWidget {
  const _CameraTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CameraCapturePage(embedded: true);
  }
}

class _NotebookTab extends ConsumerWidget {
  const _NotebookTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NotebookListPage(embedded: true);
  }
}

class _ReviewTab extends ConsumerWidget {
  const _ReviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ReviewSessionPage(embedded: true);
  }
}

/// 设置页。排序：外观 → AI 服务商 → 通知设置 → 云备份 → 数据与关于
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
        AppToast.info(context, '正式版不含调试画廊');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(defaultAiConfigProvider);
    final configName = configAsync.valueOrNull?.name;

    // 通知设置
    final notifyEnabled =
        ref.watch(settingsServiceProvider).notifyReviewEnabled;
    final notifyTime = ref.watch(settingsServiceProvider).reviewNotifyTime;

    return Scaffold(
      appBar: growthAppBar(context, title: '设置'),
      body: GrowthBackground(
        child: ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            // ===== 常规 =====
            _GroupLabel(label: '常规'),
            const _AppearanceCard(),
            const SizedBox(height: GrowthSpacing.md),
            GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('每日复习提醒'),
                    subtitle: const Text('到期复习时推送通知'),
                    value: notifyEnabled,
                    activeThumbColor: GrowthColors.primary,
                    onChanged: (v) => _toggleNotify(v),
                  ),
                  if (notifyEnabled)
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded,
                          color: GrowthColors.primary),
                      title: const Text('提醒时间'),
                      trailing: Text(
                        notifyTime,
                        style: TextStyle(
                          fontSize: 16,
                          color: GrowthColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _parseTime(notifyTime),
                        );
                        if (picked != null) {
                          final newTime =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          final settings = ref.read(settingsServiceProvider);
                          unawaited(
                              settings.setReviewNotifyTime(newTime).then((_) {
                            if (context.mounted) setState(() {});
                          }));
                          unawaited(_scheduleReminder(settings));
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.lg),

            // ===== AI 助手 =====
            _GroupLabel(label: 'AI 助手'),
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
            GlassCard(
              onTap: () => context.push('/settings/ai-call-log'),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: GrowthColors.primary),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI 调用日志',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: GrowthSpacing.xs),
                        Text(
                          '查看知识点识别等 AI 调用记录',
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

            // ===== 数据与同步 =====
            _GroupLabel(label: '数据与同步'),
            GlassCard(
              onTap: () => context.push('/settings/cloud-sync'),
              child: Row(
                children: [
                  const Icon(Icons.cloud_sync_rounded,
                      color: GrowthColors.primary),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('云同步',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: GrowthSpacing.xs),
                        Text(
                          '错题与进度自动同步 · 换机可恢复',
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
            GlassCard(
              onTap: () => context.push('/settings/backup'),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_rounded,
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
            GlassCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.backup_rounded,
                    title: '本地数据导出',
                    subtitle: '全库导出为 JSON 文件',
                    onTap: _exportBackup,
                  ),
                  const _Divider(),
                  _SettingRow(
                    icon: Icons.cleaning_services_rounded,
                    title: '图片缓存清理',
                    subtitle: '删除拍题图片与图片缓存',
                    onTap: _cleanImageCache,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.lg),

            // ===== 其他 =====
            _GroupLabel(label: '其他'),
            const _ExamBankCard(),
            const SizedBox(height: GrowthSpacing.md),
            const _EngineStatusCard(),
            const SizedBox(height: GrowthSpacing.md),
            GlassCard(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '';
                  return _SettingRow(
                    icon: Icons.info_outline_rounded,
                    title: '关于智析录',
                    subtitle: version.isEmpty ? '版本信息' : '版本 v$version',
                    onTap: _onVersionTap,
                  );
                },
              ),
            ),

            const SizedBox(height: GrowthSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// 开启/关闭每日提醒：前置说明 → 系统权限 → 调度
  Future<void> _toggleNotify(bool v) async {
    final settings = ref.read(settingsServiceProvider);
    if (v) {
      // 权限前置说明：先讲清楚再请求，避免系统弹窗突兀
      final ok = await showGrowthDialog(
        context: context,
        title: '开启每日复习提醒？',
        message: '系统会请求通知权限，用于在每天你设定的时间提醒到期复习。'
            '只会发复习提醒，不发其他打扰内容。',
        confirmLabel: '继续开启',
      );
      if (ok != true || !mounted) return;
      final granted = await NotificationService.requestPermission();
      if (!mounted) return;
      if (!granted) {
        AppToast.error(context, '通知权限被拒绝，可在系统设置中手动开启');
        return;
      }
      await settings.setNotifyReviewEnabled(true);
      await _scheduleReminder(settings);
    } else {
      await settings.setNotifyReviewEnabled(false);
      await NotificationService.cancel();
    }
    if (mounted) setState(() {});
  }

  /// 按当前设置时间调度每日提醒
  Future<void> _scheduleReminder(SettingsService settings) async {
    final t = _parseTime(settings.reviewNotifyTime);
    final dueCount = await ref.read(reviewRepositoryProvider).dueCount();
    await NotificationService.scheduleDaily(
      hour: t.hour,
      minute: t.minute,
      dueCount: dueCount,
    );
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
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

/// 外观设置卡：主题三态（跟随系统/浅色/深色），持久化，默认跟随系统
/// 深色模式全页对比度 ≥ 4.5:1
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dark_mode_outlined, color: GrowthColors.primary),
              const SizedBox(width: GrowthSpacing.md),
              Expanded(
                  child: Text('外观',
                      style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: GrowthSpacing.sm),
          for (final (m, label, icon) in [
            (ThemeMode.system, '跟随系统', Icons.brightness_auto_rounded),
            (ThemeMode.light, '浅色', Icons.light_mode_rounded),
            (ThemeMode.dark, '深色', Icons.dark_mode_rounded),
          ])
            InkWell(
              onTap: () => ref.read(themeModeProvider.notifier).set(m),
              borderRadius: BorderRadius.circular(GrowthRadii.icon),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: GrowthSpacing.xs),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 18,
                        color: mode == m
                            ? GrowthColors.primary
                            : GrowthColors.gray4),
                    const SizedBox(width: GrowthSpacing.sm),
                    Expanded(
                      child: Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: mode == m ? FontWeight.w600 : null,
                              )),
                    ),
                    if (mode == m)
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: GrowthColors.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 增强引擎状态卡（v15：OpenCV 可选，未加载时手动功能仍可用）
/// 内置真题库信息卡（GAOKAO-Bench 真实高考题）
class _ExamBankCard extends ConsumerStatefulWidget {
  const _ExamBankCard();

  @override
  ConsumerState<_ExamBankCard> createState() => _ExamBankCardState();
}

class _ExamBankCardState extends ConsumerState<_ExamBankCard> {
  int _count = 0;
  int _subjects = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await ExamBankRepository.count();
    final subjects = await ExamBankRepository.subjects();
    if (mounted) {
      setState(() {
        _count = count;
        _subjects = subjects.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(GrowthSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.school_rounded,
              color: GrowthColors.primary, size: 20),
          const SizedBox(width: GrowthSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('内置真题库', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  _count > 0
                      ? '$_count 道真实高考题（2010-2022 · $_subjects 科）· 举一反三优先出真题'
                      : '真实高考题库加载中…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineStatusCard extends ConsumerStatefulWidget {
  const _EngineStatusCard();

  @override
  ConsumerState<_EngineStatusCard> createState() => _EngineStatusCardState();
}

class _EngineStatusCardState extends ConsumerState<_EngineStatusCard> {
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await ref.read(scannerBridgeProvider).getStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      // OpenCV 未加载时静默，不阻塞
      if (mounted) setState(() => _status = {'loaded': false, 'version': ''});
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final loaded = status?['loaded'] == true;
    final version = (status?['version'] ?? '').toString();
    return GlassCard(
      padding: const EdgeInsets.all(GrowthSpacing.md),
      child: Row(
        children: [
          Icon(
            loaded ? Icons.memory_rounded : Icons.memory_outlined,
            color: loaded ? GrowthColors.success : GrowthColors.gray4,
            size: 20,
          ),
          const SizedBox(width: GrowthSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '增强引擎',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  loaded
                      ? '已加载（OpenCV $version）：自动纸面检测可用'
                      : '未加载：手动裁剪/旋转/基础增强全部正常使用',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (loaded ? GrowthColors.success : GrowthColors.gray4)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(GrowthRadii.icon),
            ),
            child: Text(
              loaded ? '已加载' : '可选',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: loaded ? GrowthColors.success : GrowthColors.gray4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
