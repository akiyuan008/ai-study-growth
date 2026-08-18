import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../growth/growth_providers.dart';

/// 成长首页 —— 系统主入口。
///
/// 结构：
/// 1. 成长身份（定性，不显示分数）
/// 2. 能力变化（能量环四能力趋势，Prompt B 空状态规则）
/// 3. 今日成长行动（NextStep + 任务清单，复习任务直达复习流）
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
          ? growthAppBar(
              context,
              title: '成长',
              actions: [_StreakBadge(dataAsync: dataAsync)],
            )
          : null,
      body: GrowthBackground(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (data) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(growthHomeProvider),
            child: ListView(
              padding: const EdgeInsets.all(GrowthSpacing.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _IdentityCard(data: data),
                const SizedBox(height: GrowthSpacing.md),
                const _TrendCard(),
                const SizedBox(height: GrowthSpacing.md),
                _NextStepCard(data: data),
                const SizedBox(height: GrowthSpacing.md),
                if (data.moments.isNotEmpty) _MemoryCard(data: data),
                const SizedBox(height: GrowthSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 身份 + 能量环卡片（Prompt B 空状态规则在此落地）
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.data});

  final GrowthHomeData data;

  void _openAbilitySheet(BuildContext context, _AbilityDetail detail) {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => _AbilityDetailSheet(detail: detail),
    );
  }

  /// 点按环体：弹出四能力明细总览（逐个可看单能力详情）
  void _openAllAbilitiesSheet(
      BuildContext context, List<_AbilityDetail> details) {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('四能力明细', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: GrowthSpacing.md),
          for (final d in details)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: d.color, shape: BoxShape.circle),
              ),
              title: Text('${d.name} · ${d.legend}',
                  style: Theme.of(context).textTheme.bodyMedium),
              subtitle: Text(d.legendCaption,
                  style: Theme.of(context).textTheme.bodySmall),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openAbilitySheet(context, d);
              },
            ),
          const SizedBox(height: GrowthSpacing.sm),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNewUser = !data.hasAnyActivity;

    final details = [
      _AbilityDetail(
        name: '学习',
        color: GrowthColors.abilityLearning,
        score: data.scores.learning,
        legend: '${data.reviewCompletedToday}/${data.reviewDueTotal}',
        legendCaption: '今日复习 完成/应完成',
        facts: [
          '完成复习 ${data.reviewCompletedToday} 次',
          '新题入库 ${data.newQuestionsToday} 道',
        ],
        meaning: '把错题变成知识资产的能力：复习完成度、新题摄入、掌握度提升。',
      ),
      _AbilityDetail(
        name: '专注',
        color: GrowthColors.abilityFocus,
        score: data.scores.focus,
        legend: '${data.focusMinutesToday}/25min',
        legendCaption: '今日真实专注 / 起步目标',
        facts: [
          '真实专注 ${data.focusMinutesToday} 分钟',
          '分心 ${data.distractionCount} 次',
        ],
        meaning: '把注意力留在任务上的能力：真实专注时长对标目标，分心轻罚。',
      ),
      _AbilityDetail(
        name: '坚持',
        color: GrowthColors.abilityPersistence,
        score: data.scores.persistence,
        legend: '${data.streak}/7天',
        legendCaption: '连续天数 / 一周目标',
        facts: ['连续学习 ${data.streak} 天'],
        meaning: '让行动成为习惯的能力：以连续天数为主，断档会重罚。',
      ),
      _AbilityDetail(
        name: '恢复',
        color: GrowthColors.abilityRecovery,
        score: data.scores.recovery,
        legend: data.distractionCount > 0
            ? '${data.recoveryCount}/${data.distractionCount}'
            : '—',
        legendCaption: '分心后回归 / 分心次数',
        facts: data.distractionCount > 0
            ? ['分心 ${data.distractionCount} 次，回归 ${data.recoveryCount} 次']
            : ['今天没有分心记录'],
        meaning: '从分心和断档中回到轨道的能力：回归率越高越强。',
      ),
    ];

    return GlassCard(
      child: Column(
        children: [
          // ---- 成长身份（定性） ----
          Text(
            isNewUser ? '能力待唤醒' : data.identity,
            style: GrowthType.pageTitle.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: GrowthSpacing.xs),
          Text(
            isNewUser
                ? '每一个行动，都会点亮一条能力弧'
                : '最强能力：${data.strongest} · 连续 ${data.streak} 天',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: GrowthSpacing.lg),

          // ---- 能量环：新用户态全灰轨道，无彩色弧 ----
          EnergyRing(
            idle: isNewUser,
            arcs: [
              for (final d in details)
                AbilityArc(
                  label: d.name,
                  // 弧长严格正比于得分；得分为 0 组件层不绘制
                  value: d.score / 100,
                  color: d.color,
                ),
            ],
            onTap: () => _openAllAbilitiesSheet(context, details),
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isNewUser ? '等待今日\n第一个行动' : '今日成长',
                  textAlign: TextAlign.center,
                  style: GrowthType.ringCenter.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (!isNewUser) ...[
                  const SizedBox(height: GrowthSpacing.xs),
                  Text(
                    data.reviewStatusLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: GrowthSpacing.md),

          // ---- 图例：带数值与目标，点按弹出单能力明细（Prompt D2） ----
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < details.length; i++) ...[
                if (i > 0) const SizedBox(width: GrowthSpacing.md),
                InkWell(
                  onTap: () => _openAbilitySheet(context, details[i]),
                  borderRadius: BorderRadius.circular(GrowthRadii.icon),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GrowthSpacing.xs,
                      vertical: GrowthSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        AbilityDot(
                          label: details[i].name,
                          color: details[i].color,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details[i].legend,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: details[i].color,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AbilityDetail {
  const _AbilityDetail({
    required this.name,
    required this.color,
    required this.score,
    required this.legend,
    required this.legendCaption,
    required this.facts,
    required this.meaning,
  });

  final String name;
  final Color color;
  final double score;
  final String legend;
  final String legendCaption;
  final List<String> facts;
  final String meaning;
}

/// 单能力明细弹层
class _AbilityDetailSheet extends StatelessWidget {
  const _AbilityDetailSheet({required this.detail});

  final _AbilityDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: detail.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: GrowthSpacing.sm),
            Text(
              '${detail.name}能力',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            Text(
              detail.legend,
              style: TextStyle(
                color: detail.color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: GrowthSpacing.sm),
        Text(detail.legendCaption,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: GrowthSpacing.md),
        Text(detail.meaning, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: GrowthSpacing.md),
        Text('今日事实', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: GrowthSpacing.sm),
        for (final f in detail.facts)
          Padding(
            padding: const EdgeInsets.only(bottom: GrowthSpacing.xs),
            child: Text('· $f', style: Theme.of(context).textTheme.bodyMedium),
          ),
        const SizedBox(height: GrowthSpacing.md),
      ],
    );
  }
}

/// NextStep 卡片
class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.data});

  final GrowthHomeData data;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GrowthSectionHeader(
            title: '下一步',
            trailing: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: GrowthColors.primary,
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
    );
  }
}

/// 今日成长行动：任务卡片（复习任务直达复习流，Prompt A2）
/// 成长趋势卡（内容契约：趋势只读展示，无执行 UI）
class _TrendCard extends ConsumerWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(growthTrendProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GrowthSectionHeader(title: '成长趋势'),
          const SizedBox(height: GrowthSpacing.sm),
          trendAsync.when(
            loading: () => const SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('加载失败：$e'),
            data: (points) {
              if (points.length < 2) {
                return SizedBox(
                  height: 72,
                  child: Center(
                    child: Text(
                      '积累 2 天以上的成长快照后，这里会出现趋势线',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 72,
                    child: CustomPaint(
                      painter: _TrendLinePainter(
                        values: points.map((p) => p.overall).toList(),
                        color: GrowthColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: GrowthSpacing.xs),
                  Text(
                    '近 ${points.length} 日综合趋势',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final maxV = 100.0;
    final stepX = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height -
          (values[i].clamp(0.0, maxV) / maxV) * (size.height - 8) -
          4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // 端点
    final lastX = (values.length - 1) * stepX;
    final lastY = size.height -
        (values.last.clamp(0.0, maxV) / maxV) * (size.height - 8) -
        4;
    canvas.drawCircle(Offset(lastX, lastY), 3.6, Paint()..color = color);
    // 数学保留
    assert(math.pi > 0);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.data});

  final GrowthHomeData data;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GrowthSectionHeader(title: '成长记忆'),
          const SizedBox(height: GrowthSpacing.sm),
          for (final moment in data.moments)
            Padding(
              padding: const EdgeInsets.only(bottom: GrowthSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: switch (moment.kind) {
                        'learning' => GrowthColors.abilityLearning,
                        'focus' => GrowthColors.abilityFocus,
                        _ => GrowthColors.success,
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

/// streak 徽章 —— 行动强调色（橙）的合法出现位置之一
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.dataAsync});

  final AsyncValue<GrowthHomeData> dataAsync;

  @override
  Widget build(BuildContext context) {
    final streak = dataAsync.valueOrNull?.streak ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: GrowthColors.actionAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(GrowthRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 16, color: GrowthColors.actionAccent),
          const SizedBox(width: 3),
          Text(
            '$streak 天',
            style: const TextStyle(
              color: GrowthColors.actionAccent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
