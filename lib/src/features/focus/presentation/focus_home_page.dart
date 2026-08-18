import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../../core/di/providers.dart';
import '../../focus/focus_providers.dart';
import '../../growth/growth_providers.dart';
import 'package:drift/drift.dart' hide Column, Table;

/// 今日专注会话
final todayFocusSessionsProvider =
    FutureProvider.autoDispose<List<FocusSession>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  return (db.select(db.focusSessions)
        ..where((t) => t.startedAt.isBiggerOrEqualValue(dayStart))
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
      .get();
});

/// 监控服务运行状态（本地态）
final monitorRunningProvider = StateProvider<bool>((ref) => false);

/// 专注 Tab 首页（Prompt A3）：
/// 当前 Mission 状态卡 + 专注会话入口（含深渊）+ 今日时间线 + 监控开关
class FocusHomePage extends ConsumerWidget {
  const FocusHomePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growthAsync = ref.watch(growthHomeProvider);
    final sessionsAsync = ref.watch(todayFocusSessionsProvider);
    final monitorRunning = ref.watch(monitorRunningProvider);

    return Scaffold(
      appBar: embedded ? AppBar(title: const Text('专注')) : null,
      body: GrowthBackground(
        child: ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            // ---- 当前任务状态卡 ----
            growthAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GrowthSectionHeader(title: '今日任务'),
                    const SizedBox(height: GrowthSpacing.sm),
                    if (data.missions.isEmpty)
                      Text(
                        '今日暂无任务，去成长页看看下一步建议',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    for (final m in data.missions)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: GrowthSpacing.sm),
                        child: Row(
                          children: [
                            Icon(
                              m.status == 'done'
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              size: 20,
                              color: m.status == 'done'
                                  ? GrowthColors.success
                                  : GrowthColors.primary,
                            ),
                            const SizedBox(width: GrowthSpacing.sm),
                            Expanded(
                              child: Text(
                                m.title,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            _StatusChip(status: m.status),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),

            // ---- 专注会话入口（普通 + 深渊） ----
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GrowthSectionHeader(title: '开始专注'),
                  const SizedBox(height: GrowthSpacing.sm),
                  Text(
                    '选一段时长进入单核专注，MOSS 会帮你挡住分心。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthButton(
                    label: '普通专注',
                    icon: Icons.self_improvement_rounded,
                    expanded: true,
                    onPressed: () => context.push('/focus'),
                  ),
                  const SizedBox(height: GrowthSpacing.sm),
                  GrowthButton(
                    label: '深渊模式（更严格的干预）',
                    icon: Icons.waves_rounded,
                    variant: GrowthButtonVariant.secondary,
                    expanded: true,
                    onPressed: () => context.push('/focus?mode=abyss'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),

            // ---- 今日专注时间线 ----
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GrowthSectionHeader(title: '今日专注时间线'),
                  const SizedBox(height: GrowthSpacing.sm),
                  sessionsAsync.when(
                    loading: () => const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('加载失败：$e'),
                    data: (sessions) {
                      if (sessions.isEmpty) {
                        return Text(
                          '今天还没有专注记录',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      return Column(
                        children: [
                          for (final s in sessions) _TimelineRow(session: s),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),

            // ---- 监控服务开关 ----
            GlassCard(
              child: Row(
                children: [
                  Icon(
                    monitorRunning ? Icons.radar_rounded : Icons.radar_outlined,
                    color: monitorRunning
                        ? GrowthColors.success
                        : GrowthColors.gray4,
                  ),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '使用监控',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          monitorRunning ? '正在感知前台应用切换' : '关闭后专注时长不含分心判定',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: monitorRunning,
                    activeThumbColor: GrowthColors.primary,
                    onChanged: (v) => _toggleMonitor(context, ref, v),
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

  Future<void> _toggleMonitor(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final bridge = ref.read(monitorBridgeProvider);
    if (value) {
      final granted = await bridge.isUsageAccessGranted();
      if (!context.mounted) return;
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'done' => ('已完成', GrowthColors.success),
      'active' => ('进行中', GrowthColors.primary),
      _ => ('待开始', GrowthColors.gray4),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(GrowthRadii.icon),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    final start = fmt.format(session.startedAt);
    final end = session.endedAt == null ? '进行中' : fmt.format(session.endedAt!);
    final minutes = session.focusMs ~/ 60000;

    return Padding(
      padding: const EdgeInsets.only(bottom: GrowthSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: session.mode == 'abyss'
                  ? GrowthColors.primaryDeep
                  : GrowthColors.abilityFocus,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: GrowthSpacing.sm),
          Expanded(
            child: Text(
              '$start - $end · ${session.mode == 'abyss' ? '深渊' : '普通'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            session.status == 'completed' || session.status == 'aborted'
                ? '专注 $minutes 分 · 分心 ${session.distractionCount} 次'
                : '进行中',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
