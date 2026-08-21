import 'dart:io';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../data/services/review_scheduler.dart';
import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// SM-2 推荐复习项（带理由标签）
class Sm2RecommendedItem {
  const Sm2RecommendedItem({
    required this.cardDbId,
    required this.question,
    required this.card,
    required this.reasons,
    required this.breadcrumb,
    required this.overdueDays,
    required this.intervalHistory,
  });

  /// review_cards 表主键（仓储评分用）
  final String cardDbId;
  final QuestionRecord question;
  final Sm2Card card;
  final List<String> reasons;
  final String breadcrumb;
  final int overdueDays;
  final List<int> intervalHistory;
}

/// SM-2 推荐引擎（v15 终版）：到期队列 + 理由标签 + 毕业区
final reviewRecommendProvider = FutureProvider.autoDispose<ReviewRecommendData>((ref) async {
  final db = ref.watch(databaseProvider);
  final scheduler = Sm2Scheduler();
  final now = DateTime.now();

  final cards = await (db.select(db.reviewCards)..orderBy([(t) => OrderingTerm.asc(t.due)])).get();
  if (cards.isEmpty) {
    return const ReviewRecommendData(items: <Sm2RecommendedItem>[], graduated: [], forecast: [0, 0, 0, 0, 0, 0, 0]);
  }

  final qIds = cards.map((c) => c.questionId).toSet().toList();
  final questions = await (db.select(db.questionRecords)..where((t) => t.id.isIn(qIds))).get();
  final qById = {for (final q in questions) q.id: q};

  // 面包屑批量查询
  final links = await db.select(db.questionKnowledgeLinks).get();
  final linkByQ = <String, String>{};
  final kpIds = links.map((l) => l.knowledgePointId).toSet().toList();
  if (kpIds.isNotEmpty) {
    final kps = await (db.select(db.knowledgePoints)..where((t) => t.id.isIn(kpIds))).get();
    final kpById = {for (final k in kps) k.id: k};
    for (final l in links) {
      final kp = kpById[l.knowledgePointId];
      if (kp == null) continue;
      final parts = [kp.subject, kp.chapter, kp.name].where((s) => s.isNotEmpty).toList();
      linkByQ[l.questionId] = parts.join(' · ');
    }
  }

  // 间隔历史：每道题相邻复习之间的天数
  final logsByQ = <String, List<DateTime>>{};
  if (qIds.isNotEmpty) {
    final logs = await (db.select(db.reviewLogs)
          ..where((t) => t.questionId.isIn(qIds))
          ..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)]))
        .get();
    for (final log in logs) {
      logsByQ.putIfAbsent(log.questionId, () => []).add(log.reviewedAt);
    }
  }
  final intervalsByQ = <String, List<int>>{};
  for (final entry in logsByQ.entries) {
    final times = entry.value;
    final intervals = <int>[];
    for (var i = 1; i < times.length && i <= 4; i++) {
      intervals.add(times[i].difference(times[i - 1]).inDays);
    }
    intervalsByQ[entry.key] = intervals;
  }

  final items = <Sm2RecommendedItem>[];
  final graduated = <QuestionRecord>[];

  for (final card in cards) {
    final q = qById[card.questionId];
    if (q == null) continue;

    // 毕业区：掌握度 5（连续答对达标）
    if (q.masteryLevel >= 5) {
      graduated.add(q);
      continue;
    }

    final sm2Card = scheduler.cardFromStorage(
      cardId: card.createdAt.millisecondsSinceEpoch,
      reps: card.reps,
      easinessFactor: card.easinessFactor,
      intervalDays: card.intervalDays,
      due: card.due,
      lastReview: card.lastReviewAt,
    );

    // 只推荐已到期
    if (!scheduler.isDue(sm2Card, now: now)) continue;

    // 理由标签（v15 终版）
    final reasons = <String>['第 ${card.reps + 1} 次'];
    final overdue = scheduler.overdueDays(sm2Card, now: now);
    if (overdue > 0) {
      reasons.add('逾期 $overdue 天');
    }

    items.add(Sm2RecommendedItem(
      cardDbId: card.id,
      question: q,
      card: sm2Card,
      reasons: reasons,
      breadcrumb: linkByQ[q.id] ?? '',
      overdueDays: overdue,
      intervalHistory: intervalsByQ[q.id] ?? const [],
    ));
  }

  // 按逾期程度排序
  items.sort((a, b) => a.overdueDays.compareTo(b.overdueDays));

  // 7 天到期预测（实时计算）
  final forecast = List<int>.filled(7, 0);
  for (final card in cards) {
    final q = qById[card.questionId];
    if (q == null || q.masteryLevel >= 5) continue;
    final days = card.due.difference(now).inDays;
    if (days >= 0 && days < 7) {
      forecast[days]++;
    }
  }

  return ReviewRecommendData(
    items: items,
    graduated: graduated,
    forecast: forecast,
  );
});

/// 复习页（v15 终版）：大图展示题目图片 + 三档标记（仍错/模糊/已会）
class ReviewSessionPage extends ConsumerStatefulWidget {
  const ReviewSessionPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends ConsumerState<ReviewSessionPage> {
  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(reviewRecommendProvider);
    return Scaffold(
      appBar: growthAppBar(context, title: '复习'),
      body: GrowthBackground(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(title: '加载失败', subtitle: '$e'),
          data: (data) {
            if (data.items.isEmpty && data.graduated.isEmpty) {
              return EmptyState(
                title: '太棒了！',
                subtitle: '没有需要复习的题目',
                actionLabel: '去拍题',
                onAction: () => context.push('/capture'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(GrowthSpacing.lg),
              children: [
                // 到期列表
                if (data.items.isNotEmpty) ...[
                  Text('待复习 (${data.items.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: GrowthSpacing.md),
                  for (final item in data.items) _ReviewCard(item: item),
                  const SizedBox(height: GrowthSpacing.xl),
                ],
                // 毕业区
                if (data.graduated.isNotEmpty) ...[
                  Text('已毕业 (${data.graduated.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: GrowthSpacing.md),
                  for (final q in data.graduated.take(5)) _GraduatedCard(question: q),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 复习卡片（v15：大图展示 + 三档评分常驻）
class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.item});

  final Sm2RecommendedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = item.question.imagePath != null &&
        File(item.question.imagePath!).existsSync();
    final scheduler = Sm2Scheduler();
    final intervals = scheduler.previewIntervals(item.card);

    return GlassCard(
      padding: const EdgeInsets.all(GrowthSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：学科标签 + 理由
          Row(
            children: [
              GrowthChip(
                label: item.question.subject,
                color: GrowthColors.primary,
              ),
              const SizedBox(width: GrowthSpacing.xs),
              for (final r in item.reasons) ...[
                const SizedBox(width: GrowthSpacing.xs),
                GrowthChip(
                  label: r,
                  color: r.contains('逾期') ? GrowthColors.warning : GrowthColors.gray4,
                ),
              ],
            ],
          ),
          const SizedBox(height: GrowthSpacing.sm),
          // 面包屑
          if (item.breadcrumb.isNotEmpty)
            Text(item.breadcrumb,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GrowthColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
          const SizedBox(height: GrowthSpacing.md),
          // 题目大图（v15：禁止占位文案）
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(GrowthRadii.card),
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.file(
                  File(item.question.imagePath!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 200),
                ),
              ),
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GrowthColors.gray2.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(GrowthRadii.card),
              ),
              child: Text('暂无图片', style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: GrowthSpacing.md),
          // 题干文字（若有真实填写）
          if (item.question.stem.isNotEmpty &&
              !item.question.stem.startsWith('（图片题'))
            Text(item.question.stem,
                style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: GrowthSpacing.md),
          // 三档评分按钮（常驻）
          Row(
            children: [
              Expanded(
                child: GrowthButton(
                  label: '仍错',
                  variant: GrowthButtonVariant.danger,
                  onPressed: () => _rate(context, ref, item, 1),
                ),
              ),
              const SizedBox(width: GrowthSpacing.sm),
              Expanded(
                child: GrowthButton(
                  label: '模糊',
                  variant: GrowthButtonVariant.secondary,
                  onPressed: () => _rate(context, ref, item, 3),
                ),
              ),
              const SizedBox(width: GrowthSpacing.sm),
              Expanded(
                child: GrowthButton(
                  label: '已会',
                  variant: GrowthButtonVariant.primary,
                  onPressed: () => _rate(context, ref, item, 5),
                ),
              ),
            ],
          ),
          const SizedBox(height: GrowthSpacing.xs),
          // 下次复习日期预览
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NextDate(label: '1 天后', days: intervals[1]?.inDays ?? 1),
              _NextDate(label: '${(intervals[3]?.inDays ?? 3)}天后', days: intervals[3]?.inDays ?? 3),
              _NextDate(label: '${(intervals[5]?.inDays ?? 7)}天后', days: intervals[5]?.inDays ?? 7),
            ],
          ),
        ],
      ),
    );
  }

  /// 评分统一走仓储：SM-2 推进 + 日志 + 掌握度联动 + 学习事件，一处不落
  Future<void> _rate(
      BuildContext context, WidgetRef ref, Sm2RecommendedItem item, int quality) async {
    final before = item.card.due;
    await ref
        .read(reviewRepositoryProvider)
        .rate(cardId: item.cardDbId, quality: quality);
    await ref.read(backupStateProvider).markDirty();
    ref.invalidate(reviewRecommendProvider);
    if (!context.mounted) return;
    // 下次日期变化证据：仍错变早 / 已会变晚
    final db = ref.read(databaseProvider);
    final rows = await (db.select(db.reviewCards)
          ..where((t) => t.id.equals(item.cardDbId)))
        .get();
    final label = switch (quality) { 1 => '仍错', 3 => '模糊', _ => '已会' };
    if (!context.mounted) return;
    if (rows.isNotEmpty) {
      final fmt = DateFormat('MM-dd');
      AppToast.success(context,
          '已标记「$label」 · 下次复习 ${fmt.format(before)} → ${fmt.format(rows.first.due)}');
    } else {
      AppToast.success(context, '已标记「$label」');
    }
  }
}

class _NextDate extends StatelessWidget {
  const _NextDate({required this.label, required this.days});
  final String label;
  final int days;
  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.bodySmall);
  }
}

/// 毕业卡片
class _GraduatedCard extends StatelessWidget {
  const _GraduatedCard({required this.question});
  final QuestionRecord question;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GrowthSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: GrowthColors.success, size: 18),
          const SizedBox(width: GrowthSpacing.sm),
          Expanded(
            child: Text(question.stem.length > 40 ? '${question.stem.substring(0, 40)}...' : question.stem,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class ReviewRecommendData {
  const ReviewRecommendData({
    required this.items,
    required this.graduated,
    required this.forecast,
  });
  final List<Sm2RecommendedItem> items;
  final List<QuestionRecord> graduated;
  final List<int> forecast;
}
