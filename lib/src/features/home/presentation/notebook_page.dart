import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'export_preview_page.dart';
import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// 列表过滤器
class NotebookFilter {
  const NotebookFilter({
    this.subject = '',
    this.keyword = '',
    this.timeRange = '全部',
    this.mastery = '全部',
  });

  final String subject;
  final String keyword;

  /// 全部 / 今天 / 近7天 / 近30天
  final String timeRange;

  /// 全部 / 已掌握 / 未掌握
  final String mastery;

  NotebookFilter copyWith({
    String? subject,
    String? keyword,
    String? timeRange,
    String? mastery,
  }) =>
      NotebookFilter(
        subject: subject ?? this.subject,
        keyword: keyword ?? this.keyword,
        timeRange: timeRange ?? this.timeRange,
        mastery: mastery ?? this.mastery,
      );
}

final notebookFilterProvider =
    StateProvider<NotebookFilter>((ref) => const NotebookFilter());

/// 全量已保存题目（过滤在本地做，Tab 计数同源）
final allQuestionsProvider =
    FutureProvider.autoDispose<List<QuestionRecord>>((ref) async {
  return ref.watch(questionRepositoryProvider).list();
});

/// 错题本列表页（Part 4.1）：
/// 科目 Tab（数量角标）+ 时间/掌握度筛选 + 多选导出
class NotebookListPage extends ConsumerStatefulWidget {
  const NotebookListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<NotebookListPage> createState() => _NotebookListPageState();
}

class _NotebookListPageState extends ConsumerState<NotebookListPage> {
  bool _selectMode = false;
  final Set<String> _selected = {};

  static const _timeRanges = ['全部', '今天', '近7天', '近30天'];
  static const _masteries = ['全部', '已掌握', '未掌握'];

  List<QuestionRecord> _applyFilter(
    List<QuestionRecord> all,
    NotebookFilter f,
  ) {
    var result = all;
    if (f.subject.isNotEmpty) {
      result = result.where((q) => q.subject == f.subject).toList();
    }
    if (f.keyword.trim().isNotEmpty) {
      final k = f.keyword.trim();
      result = result
          .where((q) =>
              q.stem.contains(k) ||
              q.tags.contains(k) ||
              (q.errorCause ?? '').contains(k))
          .toList();
    }
    final now = DateTime.now();
    switch (f.timeRange) {
      case '今天':
        final dayStart = DateTime(now.year, now.month, now.day);
        result = result.where((q) => q.createdAt.isAfter(dayStart)).toList();
      case '近7天':
        result = result
            .where((q) =>
                q.createdAt.isAfter(now.subtract(const Duration(days: 7))))
            .toList();
      case '近30天':
        result = result
            .where((q) =>
                q.createdAt.isAfter(now.subtract(const Duration(days: 30))))
            .toList();
    }
    switch (f.mastery) {
      case '已掌握':
        result = result.where((q) => q.masteryLevel >= 4).toList();
      case '未掌握':
        result = result.where((q) => q.masteryLevel < 4).toList();
    }
    return result;
  }

  /// 科目 Tab 计数（不随科目切换变化）
  Map<String, int> _subjectCounts(List<QuestionRecord> all) {
    final counts = <String, int>{};
    for (final q in all) {
      final key = q.subject.isEmpty ? '其他' : q.subject;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  /// 多选导出（v14 流程：多选→打印设置 sheet→白纸预览→出口）
  void _exportSelected(List<QuestionRecord> filtered) {
    if (_selected.isEmpty) return;
    final ids = filtered
        .where((q) => _selected.contains(q.id))
        .map((q) => q.id)
        .toList();
    _exitSelectMode();
    showPdfSettingsSheet(context, ref, ids: ids);
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allQuestionsProvider);
    final filter = ref.watch(notebookFilterProvider);

    return Scaffold(
      appBar: growthAppBar(
        context,
        title: _selectMode ? '已选 ${_selected.length} 题' : '错题本',
        showBack: !widget.embedded && !_selectMode,
        onBack: () => context.pop(),
        actions: _selectMode
            ? [
                TextButton(
                  onPressed: _exitSelectMode,
                  child: const Text('取消'),
                ),
              ]
            : [
                // 拍题入口语境化：错题本右上大按钮
                Padding(
                  padding: const EdgeInsets.only(top: GrowthSpacing.sm),
                  child: GrowthButton(
                    label: '拍题',
                    icon: Icons.camera_alt_rounded,
                    onPressed: () => context.push('/capture'),
                  ),
                ),
              ],
      ),
      body: GrowthBackground(
        child: allAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            title: '加载出了点问题',
            subtitle: '$e',
            actionLabel: '重试',
            onAction: () => setState(() {}),
          ),
          data: (all) {
            if (all.isEmpty) {
              return EmptyState(
                title: '错题本还是空的',
                subtitle: '拍下第一道错题，把它变成成长资产',
                actionLabel: '拍第一道题',
                onAction: () => context.push('/capture'),
              );
            }
            final counts = _subjectCounts(all);
            final filtered = _applyFilter(all, filter);

            return Column(
              children: [
                // 搜索 + 筛选
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      GrowthSpacing.lg, 0, GrowthSpacing.lg, GrowthSpacing.sm),
                  child: GrowthTextField(
                    hint: '搜索题干、标签、错因…',
                    onChanged: (v) => ref
                        .read(notebookFilterProvider.notifier)
                        .update((f) => f.copyWith(keyword: v)),
                  ),
                ),
                // 科目 Tab（数量角标）
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: GrowthSpacing.lg),
                    children: [
                      _SubjectTab(
                        label: '全部',
                        count: all.length,
                        selected: filter.subject.isEmpty,
                        onTap: () => ref
                            .read(notebookFilterProvider.notifier)
                            .update((f) => f.copyWith(subject: '')),
                      ),
                      for (final entry in counts.entries)
                        _SubjectTab(
                          label: entry.key,
                          count: entry.value,
                          selected: filter.subject == entry.key,
                          onTap: () => ref
                              .read(notebookFilterProvider.notifier)
                              .update((f) => f.copyWith(subject: entry.key)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: GrowthSpacing.xs),
                // 时间 / 掌握度筛选
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: GrowthSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterMenu(
                          value: filter.timeRange,
                          options: _timeRanges,
                          icon: Icons.schedule_rounded,
                          onChanged: (v) => ref
                              .read(notebookFilterProvider.notifier)
                              .update((f) => f.copyWith(timeRange: v)),
                        ),
                      ),
                      const SizedBox(width: GrowthSpacing.sm),
                      Expanded(
                        child: _FilterMenu(
                          value: filter.mastery,
                          options: _masteries,
                          icon: Icons.flag_rounded,
                          onChanged: (v) => ref
                              .read(notebookFilterProvider.notifier)
                              .update((f) => f.copyWith(mastery: v)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GrowthSpacing.sm),
                // 列表
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          title: '没有匹配的题目',
                          subtitle: '换个筛选条件试试',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(GrowthSpacing.lg),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: GrowthSpacing.sm),
                          itemBuilder: (context, i) {
                            final q = filtered[i];
                            return _QuestionCard(
                              question: q,
                              selectMode: _selectMode,
                              selected: _selected.contains(q.id),
                              onTap: () {
                                if (_selectMode) {
                                  _toggleSelect(q.id);
                                } else {
                                  context.push('/notebook/${q.id}');
                                }
                              },
                              onLongPress: () {
                                if (!_selectMode) {
                                  setState(() {
                                    _selectMode = true;
                                    _selected.add(q.id);
                                  });
                                }
                              },
                            );
                          },
                        ),
                ),
                // 多选操作栏
                if (_selectMode)
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      GrowthSpacing.lg,
                      GrowthSpacing.sm,
                      GrowthSpacing.lg,
                      MediaQuery.of(context).padding.bottom + GrowthSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: GrowthColors.glassLight,
                      border: Border(
                        top: BorderSide(color: GrowthColors.gray2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GrowthButton(
                            label: '导出题目（PDF）',
                            icon: Icons.picture_as_pdf_rounded,
                            onPressed: () => _exportSelected(filtered),
                          ),
                        ),
                        const SizedBox(width: GrowthSpacing.sm),
                        GrowthButton(
                          label: '全选',
                          variant: GrowthButtonVariant.secondary,
                          onPressed: () {
                            setState(() {
                              _selected.clear();
                              _selected.addAll(filtered.map((q) => q.id));
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubjectTab extends StatelessWidget {
  const _SubjectTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: GrowthSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GrowthRadii.pill),
        child: AnimatedContainer(
          duration: GrowthMotion.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: GrowthSpacing.md, vertical: GrowthSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? GrowthColors.primary
                : GrowthColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(GrowthRadii.pill),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : GrowthColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : GrowthColors.primary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      onSelected: onChanged,
      initialValue: value,
      itemBuilder: (context) => [
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: GrowthSpacing.sm, vertical: GrowthSpacing.sm),
        decoration: BoxDecoration(
          color: GrowthColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(GrowthRadii.icon),
          border: Border.all(
            color: GrowthColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: GrowthColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: GrowthColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: GrowthColors.primary),
          ],
        ),
      ),
    );
  }
}

/// 题目卡片：缩略图或题干摘录 + 掌握度旗标 + 日期
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final QuestionRecord question;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        question.imagePath != null && File(question.imagePath!).existsSync();
    final date = DateFormat('MM-dd').format(question.updatedAt);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(GrowthRadii.card),
      child: AnimatedContainer(
        duration: GrowthMotion.fast,
        decoration: BoxDecoration(
          color: GrowthColors.glassLight,
          borderRadius: BorderRadius.circular(GrowthRadii.card),
          border: Border.all(
            color:
                selected ? GrowthColors.primary : GrowthColors.glassBorderLight,
            width: selected ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.all(GrowthSpacing.md),
        child: Row(
          children: [
            if (selectMode)
              Padding(
                padding: const EdgeInsets.only(right: GrowthSpacing.sm),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: selected ? GrowthColors.primary : GrowthColors.gray3,
                  size: 22,
                ),
              ),
            // 缩略图（有图显示图，无图显示题干摘录）
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(GrowthRadii.icon),
                child: Image.file(
                  File(question.imagePath!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: GrowthColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(GrowthRadii.icon),
                ),
                child: const Icon(Icons.description_outlined,
                    color: GrowthColors.primary, size: 24),
              ),
            const SizedBox(width: GrowthSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.stem,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: GrowthSpacing.xs),
                  Row(
                    children: [
                      _MasteryFlag(level: question.masteryLevel),
                      const Spacer(),
                      Text(date, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 掌握度旗标（详情页可点按切换，此处只读展示）
class MasteryFlag extends StatelessWidget {
  const MasteryFlag({super.key, required this.level, this.onTap});

  final int level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      >= 5 => ('已掌握', GrowthColors.success),
      4 => ('稳定', GrowthColors.learning),
      3 => ('长期记忆', GrowthColors.actionAccent),
      2 => ('巩固中', GrowthColors.abilityRecovery),
      1 => ('初学', GrowthColors.warning),
      _ => ('新题', GrowthColors.primary),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GrowthRadii.icon),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(GrowthRadii.icon),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryFlag extends StatelessWidget {
  const _MasteryFlag({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return MasteryFlag(level: level);
  }
}
