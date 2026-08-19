import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design_system/design_system.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/question_repository.dart';
import '../../learning/learning_providers.dart';

final notebookListProvider = FutureProvider.autoDispose
    .family<List<QuestionRecord>, ({String subject, String keyword})>(
        (ref, filter) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.list(
    subject: filter.subject.isEmpty ? null : filter.subject,
    keyword: filter.keyword.isEmpty ? null : filter.keyword,
  );
});

/// 错题本列表页
class NotebookListPage extends ConsumerStatefulWidget {
  const NotebookListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<NotebookListPage> createState() => _NotebookListPageState();
}

class _NotebookListPageState extends ConsumerState<NotebookListPage> {
  String _keyword = '';
  String _subject = '';

  static const _subjectFilters = ['全部', '数学', '语文', '英语', '物理', '化学', '生物'];

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(
      notebookListProvider((subject: _subject, keyword: _keyword)),
    );
    // Part 1：拍题入口语境化——错题本页右上大按钮
    final captureButton = Padding(
      padding: const EdgeInsets.only(top: GrowthSpacing.sm),
      child: GrowthButton(
        label: '拍题',
        icon: Icons.camera_alt_rounded,
        onPressed: () => context.push('/capture'),
      ),
    );

    return Scaffold(
      appBar: growthAppBar(
        context,
        title: '错题本',
        showBack: !widget.embedded,
        onBack: () => context.pop(),
        actions: [
          IconButton(
            tooltip: '学习统计',
            onPressed: () => context.push('/stats'),
            icon: const GrowthIcon(
              type: GrowthIconType.chart,
              size: 22,
            ),
          ),
          captureButton,
        ],
      ),
      body: GrowthBackground(
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GrowthSpacing.lg,
              0,
              GrowthSpacing.lg,
              GrowthSpacing.sm,
            ),
            child: GrowthTextField(
              hint: '搜索题干、标签、错因…',
              onChanged: (v) => setState(() => _keyword = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: GrowthSpacing.lg),
              itemCount: _subjectFilters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: GrowthSpacing.sm),
              itemBuilder: (context, i) {
                final s = _subjectFilters[i];
                final selected =
                    (s == '全部' && _subject.isEmpty) || s == _subject;
                return GrowthChip(
                  label: s,
                  selected: selected,
                  onTap: () => setState(() => _subject = s == '全部' ? '' : s),
                );
              },
            ),
          ),
          const SizedBox(height: GrowthSpacing.sm),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('加载出了点问题',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: GrowthSpacing.sm),
                    Text('$e', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthButton(
                      label: '重试',
                      onPressed: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              data: (questions) {
                if (questions.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GrowthEmptyState(
                        message: _keyword.isEmpty && _subject.isEmpty
                            ? '错题本还是空的\n拍下第一道错题，把它变成成长资产'
                            : '没有匹配的题目',
                      ),
                      if (_keyword.isEmpty && _subject.isEmpty)
                        GrowthButton(
                          label: '拍第一道题',
                          icon: Icons.camera_alt_rounded,
                          onPressed: () => context.push('/capture'),
                        ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(GrowthSpacing.lg),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: GrowthSpacing.md),
                  itemBuilder: (context, i) =>
                      _QuestionCard(question: questions[i]),
                );
              },
            ),
          ),
        ],
      )),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final QuestionRecord question;

  @override
  Widget build(BuildContext context) {
    final tags = QuestionRepository.decodeTags(question.tags);
    final date = DateFormat('MM-dd').format(question.updatedAt);

    return GrowthCard(
      onTap: () => context.push('/notebook/${question.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GrowthChip(
                  label: question.subject.isEmpty ? '其他' : question.subject),
              const SizedBox(width: GrowthSpacing.sm),
              _MasteryBadge(level: question.masteryLevel),
              const Spacer(),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: GrowthSpacing.sm),
          Text(
            question.stem,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: GrowthSpacing.sm),
            Wrap(
              spacing: GrowthSpacing.xs,
              runSpacing: GrowthSpacing.xs,
              children: [
                for (final t in tags.take(4))
                  GrowthChip(
                    label: t,
                    color: GrowthColors.abilityPersistence,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 掌握度徽章（0-5）
class _MasteryBadge extends StatelessWidget {
  const _MasteryBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      >= 5 => ('已掌握', GrowthColors.success),
      4 => ('稳定', GrowthColors.abilityLearning),
      3 => ('长期记忆', GrowthColors.abilityFocus),
      2 => ('巩固中', GrowthColors.abilityFocus),
      1 => ('初学', GrowthColors.caution),
      _ => ('新题', GrowthColors.primary),
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
