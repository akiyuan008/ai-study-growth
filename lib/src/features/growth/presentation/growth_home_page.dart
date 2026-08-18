import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../growth/growth_providers.dart';

/// 成长首页 —— 系统主入口。
///
/// 五层结构（用户拍板）：
/// 1. 成长身份（定性，不显示分数）
/// 2. 能力变化（能量环四能力趋势）
/// 3. 今日成长行动（NextStep + 任务清单）
/// 4. 成长记忆（双域事件时间线）
/// 5. 快捷入口（专注/拍题）
class GrowthHomePage extends ConsumerWidget {
  const GrowthHomePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(growthHomeProvider);

    return Scaffold(
      appBar: embedded
          ? AppBar(
              title: const Text('成长'),
              actions: [
                _StreakBadge(dataAsync: dataAsync),
                const SizedBox(width: GrowthSpacing.md),
              ],
            )
          : null,
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(growthHomeProvider),
          child: ListView(
            padding: const EdgeInsets.all(GrowthSpacing.lg),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // ---- 1+2 成长身份 + 能量环 ----
              GrowthCard(
                child: Column(
                  children: [
                    Text(
                      data.identity,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: GrowthSpacing.xs),
                    Text(
                      '最强能力：${data.strongest} · 连续 ${data.streak} 天',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: GrowthSpacing.lg),
                    EnergyRing(
                      arcs: [
                        AbilityArc(
                          label: '学习',
                          value: data.scores.learning / 100,
                          color: GrowthColors.abilityLearning,
                        ),
                        AbilityArc(
                          label: '专注',
                          value: data.scores.focus / 100,
                          color: GrowthColors.abilityFocus,
                        ),
                        AbilityArc(
                          label: '坚持',
                          value: data.scores.persistence / 100,
                          color: GrowthColors.abilityPersistence,
                        ),
                        AbilityArc(
                          label: '恢复',
                          value: data.scores.recovery / 100,
                          color: GrowthColors.abilityRecovery,
                        ),
                      ],
                      centerWidget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '今日成长',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: GrowthSpacing.xs),
                          Text(
                            data.dueReviewCount > 0
                                ? '${data.dueReviewCount} 道题待复习'
                                : '复习已清空',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        AbilityDot(
                            label: '学习', color: GrowthColors.abilityLearning),
                        SizedBox(width: GrowthSpacing.md),
                        AbilityDot(
                            label: '专注', color: GrowthColors.abilityFocus),
                        SizedBox(width: GrowthSpacing.md),
                        AbilityDot(
                            label: '坚持',
                            color: GrowthColors.abilityPersistence),
                        SizedBox(width: GrowthSpacing.md),
                        AbilityDot(
                            label: '恢复', color: GrowthColors.abilityRecovery),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GrowthSpacing.md),

              // ---- 3 NextStep ----
              GrowthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GrowthSectionHeader(
                      title: '下一步',
                      trailing: Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: GrowthColors.flow,
                      ),
                    ),
                    const SizedBox(height: GrowthSpacing.sm),
                    Text(
                      data.nextStep.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: GrowthSpacing.xs),
                    Text(
                      data.nextStep.reason,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthButton(
                      label: data.nextStep.actionLabel,
                      expanded: true,
                      onPressed: () => context.push(data.nextStep.route),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GrowthSpacing.md),

              // ---- 今日任务 ----
              if (data.missions.isNotEmpty) ...[
                GrowthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GrowthSectionHeader(title: '今日成长行动'),
                      const SizedBox(height: GrowthSpacing.sm),
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
                                    ? GrowthColors.growth
                                    : GrowthColors.seed.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: GrowthSpacing.sm),
                              Expanded(
                                child: Text(
                                  m.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: m.status == 'done'
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                            : null,
                                      ),
                                ),
                              ),
                              if (m.status != 'done' &&
                                  m.source == 'review_engine')
                                TextButton(
                                  onPressed: () => context.push('/review'),
                                  child: const Text('去完成'),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: GrowthSpacing.md),
              ],

              // ---- 快捷入口 ----
              Row(
                children: [
                  Expanded(
                    child: GrowthButton(
                      label: '开始专注',
                      icon: Icons.self_improvement_rounded,
                      variant: GrowthButtonVariant.secondary,
                      onPressed: () => context.push('/focus'),
                    ),
                  ),
                  const SizedBox(width: GrowthSpacing.sm),
                  Expanded(
                    child: GrowthButton(
                      label: '拍题',
                      icon: Icons.camera_alt_rounded,
                      variant: GrowthButtonVariant.secondary,
                      onPressed: () => context.push('/capture'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GrowthSpacing.md),

              // ---- 4 成长记忆 ----
              if (data.moments.isNotEmpty)
                GrowthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GrowthSectionHeader(title: '成长记忆'),
                      const SizedBox(height: GrowthSpacing.sm),
                      for (final moment in data.moments)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: GrowthSpacing.sm),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: switch (moment.kind) {
                                    'learning' => GrowthColors.abilityLearning,
                                    'focus' => GrowthColors.abilityFocus,
                                    _ => GrowthColors.growth,
                                  },
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: GrowthSpacing.sm),
                              Expanded(
                                child: Text(
                                  moment.label,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                _timeLabel(moment.at),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: GrowthSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime at) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24 && at.day == now.day) return '${diff.inHours} 小时前';
    return '${at.month}/${at.day}';
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.dataAsync});

  final AsyncValue<GrowthHomeData> dataAsync;

  @override
  Widget build(BuildContext context) {
    final streak = dataAsync.valueOrNull?.streak ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: GrowthColors.flow.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(GrowthRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 16, color: GrowthColors.flow),
          const SizedBox(width: 3),
          Text(
            '$streak 天',
            style: const TextStyle(
              color: GrowthColors.flow,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
