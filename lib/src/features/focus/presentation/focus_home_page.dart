import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/ai/ai_message.dart';
import '../../../core/di/providers.dart';
import '../../../core/growth/mission_engine.dart';

import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../focus/focus_providers.dart';
import '../../growth/growth_providers.dart';
import '../../learning/learning_providers.dart'
    show aiGatewayProvider, backupStateProvider;
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
      appBar: embedded ? growthAppBar(context, title: '专注') : null,
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
                    GrowthSectionHeader(
                      title: '今日任务',
                      trailing: TextButton(
                        onPressed: () => _openCreateMission(context, ref),
                        child: const Text('+ 创建'),
                      ),
                    ),
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

            // ---- MOSS 伴读（自律域对账补缺） ----
            GlassCard(
              onTap: () => _openMossChat(context, ref),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_rounded,
                      color: GrowthColors.primary),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MOSS 伴读',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          '聊聊学习状态，帮你找回节奏',
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

  /// 手动创建任务（source=MANUAL）
  void _openCreateMission(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    var focusMinutes = 0;
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('创建任务', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: GrowthSpacing.md),
            GrowthTextField(
              controller: controller,
              label: '任务内容',
              hint: '例如：整理物理错题 / 背 30 个单词',
            ),
            const SizedBox(height: GrowthSpacing.md),
            Text('绑定专注时长（可选）', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: GrowthSpacing.sm),
            Wrap(
              spacing: GrowthSpacing.sm,
              children: [
                for (final m in [0, 25, 45, 60])
                  GrowthChip(
                    label: m == 0 ? '不绑定' : '$m 分钟',
                    selected: focusMinutes == m,
                    onTap: () => setSheetState(() => focusMinutes = m),
                  ),
              ],
            ),
            const SizedBox(height: GrowthSpacing.lg),
            GrowthButton(
              label: '创建',
              expanded: true,
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) return;
                await MissionEngine.createManualMission(
                  ref.read(databaseProvider),
                  title: title,
                  at: DateTime.now(),
                  focusMinutes: focusMinutes,
                );
                await ref.read(backupStateProvider).markDirty();
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                ref.invalidate(growthHomeProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// MOSS 伴读对话（流式）
  void _openMossChat(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final history = <AiMessage>[];
    var streaming = '';
    var busy = false;

    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Text('MOSS 伴读', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: GrowthSpacing.md),
              Expanded(
                child: ListView(
                  children: [
                    if (history.isEmpty && streaming.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(GrowthSpacing.lg),
                        child: Text(
                          '我是 MOSS。今天学得怎么样？要不要聊聊节奏？',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final m in history)
                      Align(
                        alignment: m.role == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin:
                              const EdgeInsets.only(bottom: GrowthSpacing.sm),
                          padding: const EdgeInsets.all(GrowthSpacing.md),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: m.role == 'user'
                                ? GrowthColors.primary.withValues(alpha: 0.14)
                                : GrowthColors.glassLight,
                            borderRadius:
                                BorderRadius.circular(GrowthRadii.field),
                          ),
                          child: Text(m.content,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ),
                    if (streaming.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin:
                              const EdgeInsets.only(bottom: GrowthSpacing.sm),
                          padding: const EdgeInsets.all(GrowthSpacing.md),
                          decoration: BoxDecoration(
                            color: GrowthColors.glassLight,
                            borderRadius:
                                BorderRadius.circular(GrowthRadii.field),
                          ),
                          child: Text(streaming,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GrowthTextField(
                      controller: controller,
                      hint: '和 MOSS 聊聊…',
                      onSubmitted: (_) {},
                    ),
                  ),
                  const SizedBox(width: GrowthSpacing.sm),
                  GrowthButton(
                    label: '发送',
                    loading: busy,
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty || busy) return;
                      controller.clear();
                      setSheetState(() {
                        busy = true;
                        streaming = '';
                        history.add(AiMessage(role: 'user', content: text));
                      });
                      final gateway = await ref.read(aiGatewayProvider.future);
                      if (gateway == null) {
                        setSheetState(() {
                          busy = false;
                          history.add(const AiMessage(
                              role: 'assistant',
                              content: '先配置 AI 服务商，我才能陪你聊天。'));
                        });
                        return;
                      }
                      final buffer = StringBuffer();
                      try {
                        await for (final delta in gateway.companionChat(
                          history: history.sublist(0, history.length - 1),
                          message: text,
                        )) {
                          buffer.write(delta);
                          setSheetState(() => streaming = buffer.toString());
                        }
                      } catch (_) {}
                      history.add(AiMessage(
                          role: 'assistant',
                          content: buffer.isEmpty ? '……' : buffer.toString()));
                      setSheetState(() {
                        busy = false;
                        streaming = '';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
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
