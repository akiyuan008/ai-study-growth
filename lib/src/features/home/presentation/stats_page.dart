import 'package:drift/drift.dart' hide Column, Table;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../data/services/ai_learning_services.dart';
import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// 统计数据
class NotebookStats {
  const NotebookStats({
    required this.total,
    required this.mastered,
    required this.dueToday,
    required this.doneToday,
    required this.knowledgeMastery,
  });

  final int total;
  final int mastered;
  final int dueToday;
  final int doneToday;

  /// 知识点 → 平均掌握度（0-5）
  final List<({String name, double mastery, int count})> knowledgeMastery;

  double get completionRate =>
      dueToday + doneToday == 0 ? 0 : doneToday / (dueToday + doneToday);
}

final notebookStatsProvider =
    FutureProvider.autoDispose<NotebookStats>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);

  final questions = await (db.select(db.questionRecords)
        ..where((t) => t.contentStatus.equals('saved')))
      .get();
  final mastered = questions.where((q) => q.masteryLevel >= 4).length;

  final dueCards = await (db.select(db.reviewCards)
        ..where((t) => t.due.isSmallerOrEqualValue(now)))
      .get();
  final doneLogs = await (db.select(db.reviewLogs)
        ..where((t) => t.reviewedAt.isBiggerOrEqualValue(dayStart)))
      .get();

  // 知识点掌握度：聚合题目-知识点关联
  final links = await db.select(db.questionKnowledgeLinks).get();
  final kps = await db.select(db.knowledgePoints).get();
  final qMastery = {for (final q in questions) q.id: q.masteryLevel};

  final byKp = <String, List<int>>{};
  for (final link in links) {
    final m = qMastery[link.questionId];
    if (m == null) continue;
    byKp.putIfAbsent(link.knowledgePointId, () => []).add(m);
  }

  final kpNames = {for (final k in kps) k.id: k.name};
  final knowledgeMastery = byKp.entries
      .map((e) => (
            name: kpNames[e.key] ?? '未知',
            mastery: e.value.reduce((a, b) => a + b) / e.value.length,
            count: e.value.length,
          ))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  return NotebookStats(
    total: questions.length,
    mastered: mastered,
    dueToday: dueCards.length,
    doneToday: doneLogs.length,
    knowledgeMastery: knowledgeMastery.take(12).toList(),
  );
});

/// 学习统计页（Part 1.3）：统计卡片 + 知识点掌握度柱状图
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(notebookStatsProvider);

    return Scaffold(
      appBar: growthAppBar(
        context,
        title: '学习统计',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: GrowthBackground(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (stats) => ListView(
            padding: const EdgeInsets.all(GrowthSpacing.lg),
            children: [
              // 统计卡片
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: '总错题',
                      value: '${stats.total}',
                      color: GrowthColors.primary,
                    ),
                  ),
                  const SizedBox(width: GrowthSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      label: '已掌握',
                      value: '${stats.mastered}',
                      color: GrowthColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GrowthSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: '今日到期',
                      value: '${stats.dueToday}',
                      color: GrowthColors.actionAccent,
                    ),
                  ),
                  const SizedBox(width: GrowthSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      label: '今日完成率',
                      value: '${(stats.completionRate * 100).round()}%',
                      color: GrowthColors.learning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GrowthSpacing.lg),

              // AI 知识点规划：学习路径建议（Part 3.3）
              _LearningPathCard(stats: stats),
              const SizedBox(height: GrowthSpacing.md),

              // 知识点掌握度柱状图
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GrowthSectionHeader(title: '知识点掌握度'),
                    const SizedBox(height: GrowthSpacing.sm),
                    if (stats.knowledgeMastery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: GrowthSpacing.lg),
                        child: Text(
                          '保存带知识点的题目后，这里会展示各知识点的平均掌握度',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 5,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final kp = stats.knowledgeMastery[groupIndex];
                                  return BarTooltipItem(
                                    '${kp.name}\n掌握 ${rod.toY.toStringAsFixed(1)} / 5 · ${kp.count} 题',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 ||
                                        i >= stats.knowledgeMastery.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final name = stats.knowledgeMastery[i].name;
                                    final short = name.length > 4
                                        ? '${name.substring(0, 4)}…'
                                        : name;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        short,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              for (var i = 0;
                                  i < stats.knowledgeMastery.length;
                                  i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: stats.knowledgeMastery[i].mastery,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          GrowthColors.primary
                                              .withValues(alpha: 0.55),
                                          GrowthColors.primary,
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
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
}

/// AI 学习路径建议卡
class _LearningPathCard extends ConsumerStatefulWidget {
  const _LearningPathCard({required this.stats});

  final NotebookStats stats;

  @override
  ConsumerState<_LearningPathCard> createState() => _LearningPathCardState();
}

class _LearningPathCardState extends ConsumerState<_LearningPathCard> {
  String? _suggestion;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final advisor = ref.read(aiPathAdvisorProvider);
    final cached = advisor.cachedSuggestion;
    if (cached != null) {
      setState(() => _suggestion = cached);
      return;
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    // 聚合知识点统计喂给 advisor
    final kps = await db.select(db.knowledgePoints).get();
    final links = await db.select(db.questionKnowledgeLinks).get();
    final questions = await db.select(db.questionRecords).get();
    final mastery = {for (final q in questions) q.id: q.masteryLevel};
    final byKp = <String, List<int>>{};
    for (final l in links) {
      final m = mastery[l.questionId];
      if (m != null) byKp.putIfAbsent(l.knowledgePointId, () => []).add(m);
    }
    final stats = [
      for (final kp in kps)
        if (byKp.containsKey(kp.id))
          KnowledgePointStat(
            id: kp.id,
            name: kp.name,
            questionCount: byKp[kp.id]!.length,
            avgMastery:
                byKp[kp.id]!.reduce((a, b) => a + b) / byKp[kp.id]!.length,
          ),
    ];
    final suggestion = await ref.read(aiPathAdvisorProvider).suggest(stats);
    if (mounted) {
      setState(() {
        _suggestion = suggestion;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GrowthSectionHeader(
            title: 'AI 知识点规划',
            trailing: TextButton(
              onPressed: _loading ? null : _refresh,
              child: const Text('刷新'),
            ),
          ),
          const SizedBox(height: GrowthSpacing.sm),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(GrowthSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_suggestion == null)
            Text(
              '配置 AI 服务商并保存带知识点的题目后，AI 会生成学习路径建议',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Text(
              _suggestion!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(GrowthSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: GrowthSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
