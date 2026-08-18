import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fsrs/fsrs.dart';

import '../../../design_system/design_system.dart';
import '../../../data/repositories/question_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../learning/learning_providers.dart';

final reviewSessionProvider =
    FutureProvider.autoDispose<List<DueReviewItem>>((ref) async {
  return ref.watch(reviewRepositoryProvider).dueItems();
});

/// 间隔复习页（FSRS）：逐卡作答 → 评分 → 下一张
class ReviewSessionPage extends ConsumerStatefulWidget {
  const ReviewSessionPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends ConsumerState<ReviewSessionPage> {
  bool _revealed = false;
  int _doneCount = 0;

  void _next() {
    setState(() => _revealed = false);
    ref.invalidate(reviewSessionProvider);
  }

  Future<void> _rate(DueReviewItem item, Rating rating) async {
    await ref
        .read(reviewRepositoryProvider)
        .rate(cardId: item.card.id, rating: rating);
    setState(() => _doneCount++);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(reviewSessionProvider);

    return Scaffold(
      appBar: widget.embedded
          ? AppBar(title: const Text('今日复习'))
          : AppBar(
              title: const Text('今日复习'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
            ),
      body: GrowthBackground(
          child: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (items) {
          if (items.isEmpty) {
            return GrowthEmptyState(
              message: _doneCount > 0
                  ? '今日复习全部完成，成长 +$_doneCount 步\n去拍几道新题，或休息一下吧'
                  : '暂无到期复习\n拍题入库后，记忆曲线会自动为你安排',
            );
          }

          final item = items.first;
          final steps = QuestionRepository.decodeSteps(item.question.keySteps);

          return Padding(
            padding: const EdgeInsets.all(GrowthSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GrowthChip(label: item.question.subject),
                    const Spacer(),
                    Text(
                      '剩余 ${items.length} 张',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: GrowthSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GrowthCard(
                          child: Text(
                            item.question.stem,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (_revealed) ...[
                          const SizedBox(height: GrowthSpacing.md),
                          GrowthCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('答案',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: GrowthSpacing.sm),
                                Text(
                                  item.question.answer ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (steps.isNotEmpty) ...[
                                  const SizedBox(height: GrowthSpacing.md),
                                  for (final (i, s) in steps.indexed) ...[
                                    Text('${i + 1}. $s',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    const SizedBox(height: GrowthSpacing.xs),
                                  ],
                                ],
                                if ((item.question.errorCause ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: GrowthSpacing.md),
                                  Text(
                                    '错因：${item.question.errorCause}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: GrowthColors.caution),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!_revealed)
                  GrowthButton(
                    label: '显示答案',
                    icon: Icons.visibility_rounded,
                    expanded: true,
                    onPressed: () => setState(() => _revealed = true),
                  )
                else
                  Row(
                    children: [
                      for (final (rating, label, color) in [
                        (Rating.again, '忘记', GrowthColors.caution),
                        (Rating.hard, '困难', GrowthColors.primary),
                        (Rating.good, '记得', GrowthColors.success),
                        (Rating.easy, '简单', GrowthColors.abilityLearning),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: GrowthSpacing.xs),
                            child: _RatingButton(
                              label: label,
                              color: color,
                              onTap: () => _rate(item, rating),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      )),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GrowthRadii.field),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(GrowthRadii.field),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
