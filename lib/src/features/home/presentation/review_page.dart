import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/question_repository.dart';
import '../../../data/services/review_scheduler.dart';
import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// 推荐复习项（带理由）
class RecommendedItem {
  const RecommendedItem({
    required this.question,
    required this.card,
    required this.reasons,
    required this.breadcrumb,
    required this.strength,
  });

  final QuestionRecord question;
  final ReviewCard card;
  final List<String> reasons;
  final String breadcrumb;
  final double strength;
}

class ReviewRecommendData {
  const ReviewRecommendData({
    required this.items,
    required this.graduated,
    required this.forecast,
  });

  final List<RecommendedItem> items;
  final List<QuestionRecord> graduated;

  /// 未来 7 天每日到期数
  final List<int> forecast;
}

/// 推荐引擎（Part 6.1）：到期队列 + 理由标签 + 毕业区 + 7 天预测
final reviewRecommendProvider =
    FutureProvider.autoDispose<ReviewRecommendData>((ref) async {
  final db = ref.watch(databaseProvider);
  final scheduler = ReviewScheduler();
  final now = DateTime.now();

  final cards = await db.select(db.reviewCards).get();
  if (cards.isEmpty) {
    return const ReviewRecommendData(
      items: [],
      graduated: [],
      forecast: [0, 0, 0, 0, 0, 0, 0],
    );
  }

  final qIds = cards.map((c) => c.questionId).toList();
  final questions = await (db.select(db.questionRecords)
        ..where((t) => t.id.isIn(qIds)))
      .get();
  final qById = {for (final q in questions) q.id: q};

  // 面包屑批量查询
  final links = await db.select(db.questionKnowledgeLinks).get();
  final linkByQ = <String, String>{};
  final kpIds = links.map((l) => l.knowledgePointId).toSet().toList();
  if (kpIds.isNotEmpty) {
    final kps = await (db.select(db.knowledgePoints)
          ..where((t) => t.id.isIn(kpIds)))
        .get();
    final kpById = {for (final k in kps) k.id: k};
    for (final l in links) {
      final kp = kpById[l.knowledgePointId];
      if (kp == null) continue;
      final parts =
          [kp.subject, kp.chapter, kp.name].where((s) => s.isNotEmpty).toList();
      linkByQ[l.questionId] = parts.join(' · ');
    }
  }

  final items = <RecommendedItem>[];
  final graduated = <QuestionRecord>[];

  for (final card in cards) {
    final q = qById[card.questionId];
    if (q == null) continue;

    // 毕业区：掌握度 5（连续答对达标）
    if (q.masteryLevel >= 5) {
      graduated.add(q);
      continue;
    }

    // 只推荐已到期
    if (card.due.isAfter(now)) continue;

    final fsrsCard = scheduler.cardFromStorage(
      cardId: card.createdAt.millisecondsSinceEpoch,
      state: card.state,
      step: card.step,
      stability: card.stability,
      difficulty: card.difficulty,
      due: card.due,
      lastReview: card.lastReviewAt,
    );
    final strength = scheduler.retrievability(fsrsCard, now: now);

    // 理由标签（Part 6.1）
    final reasons = <String>['第 ${card.reps + 1} 次复习'];
    final overdueDays = now.difference(card.due).inDays;
    if (overdueDays >= 1) {
      reasons.add('逾期 $overdueDays 天');
    }
    if (card.lastReviewAt != null && strength < 0.7 && strength > 0.3) {
      reasons.add('强度将跌破阈值');
    }

    items.add(RecommendedItem(
      question: q,
      card: card,
      reasons: reasons,
      breadcrumb: linkByQ[q.id] ?? '',
      strength: strength,
    ));
  }

  // 按逾期程度排序
  items.sort((a, b) => a.card.due.compareTo(b.card.due));

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

/// 复习页（Part 6）：推荐复习（主视图）+ 屏内复习（备选路径）
class ReviewSessionPage extends ConsumerStatefulWidget {
  const ReviewSessionPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends ConsumerState<ReviewSessionPage> {
  int _tab = 0;
  bool _showGraduated = false;
  int _doneCount = 0;

  Future<void> _mark(RecommendedItem item, Rating rating) async {
    unawaited(HapticFeedback.selectionClick());
    await ref
        .read(reviewRepositoryProvider)
        .rate(cardId: item.card.id, rating: rating);
    await ref.read(backupStateProvider).markDirty();
    setState(() => _doneCount++);
    ref.invalidate(reviewRecommendProvider);
    final msg = switch (rating) {
      Rating.again => '已标记「仍错」：间隔缩短，重新进入推荐',
      Rating.hard => '已标记「模糊」：间隔小幅缩短',
      _ => '已标记「已会」：间隔拉长，连续答对将毕业',
    };
    if (mounted) AppToast.info(context, msg);
  }

  /// 毕业区拉回
  Future<void> _pullBack(QuestionRecord q) async {
    await ref.read(questionRepositoryProvider).updateMastery(q.id, 3);
    ref.invalidate(reviewRecommendProvider);
    if (mounted) AppToast.info(context, '已拉回推荐池');
  }

  @override
  Widget build(BuildContext context) {
    final recAsync = ref.watch(reviewRecommendProvider);

    return Scaffold(
      appBar: growthAppBar(
        context,
        title: '复习',
        showBack: !widget.embedded,
        onBack: () => context.pop(),
      ),
      body: GrowthBackground(
        child: Column(
          children: [
            // Tab：推荐 / 屏内
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GrowthSpacing.lg),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('推荐复习')),
                  ButtonSegment(value: 1, label: Text('屏内复习')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
            ),
            const SizedBox(height: GrowthSpacing.sm),
            Expanded(
              child: _tab == 0
                  ? _buildRecommendTab(recAsync)
                  : const _InScreenReview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendTab(AsyncValue<ReviewRecommendData> recAsync) {
    return recAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        title: '加载出了点问题',
        subtitle: '$e',
        actionLabel: '重试',
        onAction: () => ref.invalidate(reviewRecommendProvider),
      ),
      data: (data) {
        if (data.items.isEmpty && data.graduated.isEmpty) {
          return EmptyState(
            title: '暂无复习安排',
            subtitle: '拍题入库后，记忆曲线会自动为你安排',
            actionLabel: '去拍题',
            onAction: () => context.push('/capture'),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            // 顶部摘要（Part 6.1）
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日推荐 ${data.items.length} · 已毕业 ${data.graduated.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: GrowthSpacing.sm),
                  if (_doneCount > 0)
                    Text(
                      '本次已完成 $_doneCount 个标记',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: GrowthSpacing.sm),
                  // 7 天到期预测（实时计算）
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _ForecastBar(
                              count: data.forecast[i],
                              label: i == 0 ? '今' : '+$i',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),

            // 推荐列表
            if (data.items.isEmpty)
              GlassCard(
                child: Text(
                  '今天的推荐都完成了，剩下的还没到期。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (final item in data.items) ...[
              _RecommendCard(
                item: item,
                onMark: _mark,
              ),
              const SizedBox(height: GrowthSpacing.sm),
            ],

            // 已毕业区（Part 6.1：可拉回）
            if (data.graduated.isNotEmpty) ...[
              const SizedBox(height: GrowthSpacing.md),
              InkWell(
                onTap: () => setState(() => _showGraduated = !_showGraduated),
                child: Row(
                  children: [
                    Icon(
                      _showGraduated
                          ? Icons.expand_more_rounded
                          : Icons.chevron_right_rounded,
                      size: 20,
                      color: GrowthColors.gray5,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '已掌握 · 不再推荐（${data.graduated.length}）',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GrowthColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showGraduated)
                for (final q in data.graduated)
                  Padding(
                    padding: const EdgeInsets.only(top: GrowthSpacing.sm),
                    child: GlassCard(
                      padding: const EdgeInsets.all(GrowthSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 18, color: GrowthColors.success),
                          const SizedBox(width: GrowthSpacing.sm),
                          Expanded(
                            child: Text(
                              q.stem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _pullBack(q),
                            child: const Text('拉回'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: GrowthSpacing.xl),
          ],
        );
      },
    );
  }
}

class _ForecastBar extends StatelessWidget {
  const _ForecastBar({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final h = count == 0 ? 4.0 : (12.0 + count * 4.0).clamp(12.0, 36.0);
    return Column(
      children: [
        AnimatedContainer(
          duration: GrowthMotion.base,
          height: h,
          decoration: BoxDecoration(
            color: count == 0 ? GrowthColors.gray3 : GrowthColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 9.5, color: GrowthColors.gray5),
        ),
      ],
    );
  }
}

/// 推荐卡：缩略图 + 题干 + 面包屑 + 理由标签 + 标记按钮
class _RecommendCard extends StatelessWidget {
  const _RecommendCard({required this.item, required this.onMark});

  final RecommendedItem item;
  final void Function(RecommendedItem, Rating) onMark;

  @override
  Widget build(BuildContext context) {
    final q = item.question;
    final hasImage = q.imagePath != null && File(q.imagePath!).existsSync();

    return GlassCard(
      padding: const EdgeInsets.all(GrowthSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(GrowthRadii.icon),
                  child: Image.file(
                    File(q.imagePath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GrowthColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(GrowthRadii.icon),
                  ),
                  child: const Icon(Icons.description_outlined,
                      size: 20, color: GrowthColors.primary),
                ),
              const SizedBox(width: GrowthSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.stem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (item.breadcrumb.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.breadcrumb,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              // 强度
              Column(
                children: [
                  Text(
                    '${(item.strength * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: GrowthColors.primary,
                    ),
                  ),
                  Text('强度', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: GrowthSpacing.sm),
          // 理由标签
          Wrap(
            spacing: GrowthSpacing.xs,
            runSpacing: GrowthSpacing.xs,
            children: [
              for (final r in item.reasons)
                GrowthChip(
                  label: r,
                  color: r.contains('逾期')
                      ? GrowthColors.warning
                      : r.contains('跌破')
                          ? GrowthColors.actionAccent
                          : GrowthColors.learning,
                ),
            ],
          ),
          const SizedBox(height: GrowthSpacing.sm),
          // 标记按钮（Part 6.3）
          Row(
            children: [
              Expanded(
                child: _MarkButton(
                  label: '仍错',
                  color: GrowthColors.warning,
                  onTap: () => onMark(item, Rating.again),
                ),
              ),
              const SizedBox(width: GrowthSpacing.sm),
              Expanded(
                child: _MarkButton(
                  label: '模糊',
                  color: GrowthColors.actionAccent,
                  onTap: () => onMark(item, Rating.hard),
                ),
              ),
              const SizedBox(width: GrowthSpacing.sm),
              Expanded(
                child: _MarkButton(
                  label: '已会',
                  color: GrowthColors.success,
                  onTap: () => onMark(item, Rating.good),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GrowthRadii.field),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(GrowthRadii.field),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
    );
  }
}

/// 屏内复习（Part 6.4 备选路径）：逐题→显示答案→四档评分→反馈卡
class _InScreenReview extends ConsumerStatefulWidget {
  const _InScreenReview();

  @override
  ConsumerState<_InScreenReview> createState() => _InScreenReviewState();
}

class _InScreenReviewState extends ConsumerState<_InScreenReview> {
  bool _revealed = false;
  int _doneCount = 0;

  void _next() {
    setState(() => _revealed = false);
    ref.invalidate(_inScreenQueueProvider);
  }

  Future<void> _rate(QuestionRecord q, ReviewCard card, Rating rating) async {
    unawaited(HapticFeedback.selectionClick());
    await ref
        .read(reviewRepositoryProvider)
        .rate(cardId: card.id, rating: rating);
    await ref.read(backupStateProvider).markDirty();
    setState(() => _doneCount++);
    ref.invalidate(reviewRecommendProvider);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(_inScreenQueueProvider);

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            title: _doneCount > 0 ? '今天的屏内复习完成了' : '暂无到期复习',
            subtitle: _doneCount > 0
                ? '已完成 $_doneCount 题，休息一下或去拍新题'
                : '拍题入库后，记忆曲线会自动为你安排',
          );
        }

        final item = items.first;
        final q = item.question;
        final card = item.card;
        final steps = QuestionRepository.decodeSteps(q.keySteps);
        final scheduler = ReviewScheduler();
        final fsrsCard = scheduler.cardFromStorage(
          cardId: card.createdAt.millisecondsSinceEpoch,
          state: card.state,
          step: card.step,
          stability: card.stability,
          difficulty: card.difficulty,
          due: card.due,
          lastReview: card.lastReviewAt,
        );
        final previews = scheduler.previewIntervals(fsrsCard);

        return ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            Row(
              children: [
                Text('剩余 ${items.length} 题',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                if (q.imagePath != null && File(q.imagePath!).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GrowthRadii.icon),
                    child: Image.file(
                      File(q.imagePath!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: GrowthSpacing.sm),
            GlassCard(
              child:
                  Text(q.stem, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: GrowthSpacing.md),
            if (!_revealed)
              GrowthButton(
                label: '显示答案',
                icon: Icons.visibility_rounded,
                expanded: true,
                onPressed: () => setState(() => _revealed = true),
              )
            else ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GrowthSectionHeader(title: '答案'),
                    const SizedBox(height: GrowthSpacing.sm),
                    Text(q.answer ?? '',
                        style: Theme.of(context).textTheme.titleLarge),
                    if (steps.isNotEmpty) ...[
                      const SizedBox(height: GrowthSpacing.sm),
                      for (final (i, s) in steps.indexed) ...[
                        Text('${i + 1}. $s',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: GrowthSpacing.xs),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: GrowthSpacing.md),
              // 四档评分（下次间隔预览）
              Row(
                children: [
                  for (final (rating, label, color) in [
                    (Rating.again, '忘记', GrowthColors.warning),
                    (Rating.hard, '困难', GrowthColors.actionAccent),
                    (Rating.good, '记得', GrowthColors.success),
                    (Rating.easy, '简单', GrowthColors.learning),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: GrowthSpacing.xs),
                        child: InkWell(
                          onTap: () => _rate(q, card, rating),
                          borderRadius:
                              BorderRadius.circular(GrowthRadii.field),
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.13),
                              borderRadius:
                                  BorderRadius.circular(GrowthRadii.field),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                Text(
                                  _intervalLabel(
                                      previews[rating] ?? Duration.zero),
                                  style: TextStyle(
                                      color: color.withValues(alpha: 0.75),
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _QueueItem {
  const _QueueItem({required this.question, required this.card});
  final QuestionRecord question;
  final ReviewCard card;
}

/// 屏内复习队列（到期 + 未毕业）
final _inScreenQueueProvider =
    FutureProvider.autoDispose<List<_QueueItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final cards = await (db.select(db.reviewCards)
        ..where((t) => t.due.isSmallerOrEqualValue(now))
        ..orderBy([(t) => OrderingTerm.asc(t.due)]))
      .get();
  if (cards.isEmpty) return const [];
  final ids = cards.map((c) => c.questionId).toList();
  final questions =
      await (db.select(db.questionRecords)..where((t) => t.id.isIn(ids))).get();
  final byId = {for (final q in questions) q.id: q};
  return cards
      .where((c) =>
          byId.containsKey(c.questionId) &&
          (byId[c.questionId]!.masteryLevel < 5))
      .map((c) => _QueueItem(question: byId[c.questionId]!, card: c))
      .toList();
});

String _intervalLabel(Duration d) {
  if (d.inMinutes < 1) return '<1分钟';
  if (d.inMinutes < 60) return '${d.inMinutes}分钟';
  if (d.inHours < 24) return '${d.inHours}小时';
  return '${d.inDays}天';
}
