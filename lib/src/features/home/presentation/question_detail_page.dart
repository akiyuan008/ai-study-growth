import 'dart:io';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/exam_bank_repository.dart';
import '../../../data/repositories/question_repository.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/generated_exercise.dart';
import '../../../domain/models/subject.dart';
import '../../../domain/models/knowledge_path.dart';
import '../../learning/learning_providers.dart';
import 'notebook_page.dart' show MasteryFlag;

/// 详情页数据聚合
class QuestionDetailData {
  const QuestionDetailData({
    required this.question,
    required this.breadcrumb,
    required this.card,
    required this.logs,
  });

  final QuestionRecord question;
  final KnowledgePath breadcrumb;
  final ReviewCard? card;
  final List<ReviewLog> logs;
}

final questionDetailProvider = FutureProvider.autoDispose
    .family<QuestionDetailData?, String>((ref, id) async {
  final db = ref.watch(databaseProvider);
  final questions = await (db.select(db.questionRecords)
        ..where((t) => t.id.equals(id)))
      .get();
  if (questions.isEmpty) return null;
  final question = questions.first;

  // 层级面包屑
  final links = await (db.select(db.questionKnowledgeLinks)
        ..where((t) => t.questionId.equals(id)))
      .get();
  KnowledgePath breadcrumb = const KnowledgePath();
  if (links.isNotEmpty) {
    final kps = await (db.select(db.knowledgePoints)
          ..where((t) => t.id.equals(links.first.knowledgePointId)))
        .get();
    if (kps.isNotEmpty) {
      final kp = kps.first;
      breadcrumb = KnowledgePath(
        subject: kp.subject,
        version: kp.version,
        book: kp.book,
        chapter: kp.chapter,
        lesson: kp.lesson,
        point: kp.name,
      );
    }
  }

  // 复习卡 + 历史
  final cards = await (db.select(db.reviewCards)
        ..where((t) => t.questionId.equals(id)))
      .get();
  final logs = await (db.select(db.reviewLogs)
        ..where((t) => t.questionId.equals(id))
        ..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)]))
      .get();

  return QuestionDetailData(
    question: question,
    breadcrumb: breadcrumb,
    card: cards.isEmpty ? null : cards.first,
    logs: logs,
  );
});

/// 题目详情页（Part 4.2 重做）：
/// 原图/题干分段切换、掌握度旗标点按切换、层级面包屑、
/// 操作仅留举一反三（删除/编辑进溢出菜单）
class QuestionDetailPage extends ConsumerStatefulWidget {
  const QuestionDetailPage({super.key, required this.questionId});

  final String questionId;

  @override
  ConsumerState<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends ConsumerState<QuestionDetailPage> {
  /// 0=原图 1=题干
  int _segment = 0;

  @override
  void initState() {
    super.initState();
    // 有图默认看原图（图片必须可见），无图看题干
    final data = ref.read(questionDetailProvider(widget.questionId));
    data.whenData((d) {
      if (d != null &&
          (d.question.imagePath == null ||
              !File(d.question.imagePath!).existsSync())) {
        _segment = 1;
      }
    });
  }

  Future<void> _delete() async {
    final ok = await showGrowthDialog(
      context: context,
      title: '删除这道题？',
      message: '删除后复习记录与题库数据一并清除，无法恢复。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    await ref.read(questionRepositoryProvider).delete(widget.questionId);
    // 云同步墓碑：下次同步时云端同步删除该题及其复习数据
    await ref.read(cloudSyncProvider).recordQuestionDeleted(widget.questionId);
    if (mounted) {
      AppToast.success(context, '已删除');
      context.pop();
    }
  }

  /// 真实编辑（v13 遗留项补齐）
  void _openEditSheet() {
    final data =
        ref.read(questionDetailProvider(widget.questionId)).valueOrNull;
    if (data == null) return;
    final q = data.question;
    final stemCtrl = TextEditingController(text: q.stem);
    final answerCtrl = TextEditingController(text: q.answer ?? '');
    final causeCtrl = TextEditingController(text: q.errorCause ?? '');
    var subject = q.subject;

    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('编辑题目', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: GrowthSpacing.md),
              Expanded(
                child: ListView(
                  children: [
                    Text('科目', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: GrowthSpacing.xs),
                    Wrap(
                      spacing: GrowthSpacing.xs,
                      runSpacing: GrowthSpacing.xs,
                      children: [
                        for (final s in Subject.values)
                          GrowthChip(
                            label: s.label,
                            selected: subject == s.label,
                            onTap: () => setSheet(() => subject = s.label),
                          ),
                      ],
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: stemCtrl,
                      label: '题干',
                      maxLines: 3,
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: answerCtrl,
                      label: '答案',
                      maxLines: 2,
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: causeCtrl,
                      label: '错因',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              GrowthButton(
                label: '保存修改',
                expanded: true,
                onPressed: () async {
                  final navigator = Navigator.of(sheetContext);
                  final messenger = ScaffoldMessenger.of(sheetContext);
                  await ref.read(questionRepositoryProvider).updateQuestion(
                        id: widget.questionId,
                        stem: stemCtrl.text.trim(),
                        answer: answerCtrl.text.trim(),
                        errorCause: causeCtrl.text.trim(),
                        subject: subject,
                      );
                  ref.invalidate(questionDetailProvider(widget.questionId));
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('已保存修改')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cycleMastery(int current) async {
    final next = (current + 1) % 6;
    await ref
        .read(questionRepositoryProvider)
        .updateMastery(widget.questionId, next);
    ref.invalidate(questionDetailProvider(widget.questionId));
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(questionDetailProvider(widget.questionId));

    return Scaffold(
      appBar: growthAppBar(
        context,
        title: '错题详情',
        showBack: true,
        onBack: () => context.pop(),
        actions: [
          // 溢出菜单：删除/编辑
          PopupMenuButton<String>(
            tooltip: '',
            onSelected: (v) {
              if (v == 'delete') _delete();
              if (v == 'edit') _openEditSheet();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('编辑')),
              PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
      body: GrowthBackground(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            title: '加载出了点问题',
            subtitle: '$e',
            actionLabel: '重试',
            onAction: () =>
                ref.invalidate(questionDetailProvider(widget.questionId)),
          ),
          data: (data) {
            if (data == null) {
              return const EmptyState(title: '题目不存在');
            }
            return _DetailBody(
              data: data,
              segment: _segment,
              onSegment: (i) => setState(() => _segment = i),
              onCycleMastery: _cycleMastery,
            );
          },
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.data,
    required this.segment,
    required this.onSegment,
    required this.onCycleMastery,
  });

  final QuestionDetailData data;
  final int segment;
  final ValueChanged<int> onSegment;
  final ValueChanged<int> onCycleMastery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = data.question;
    final hasImage = q.imagePath != null && File(q.imagePath!).existsSync();
    final steps = QuestionRepository.decodeSteps(q.keySteps);

    return ListView(
      padding: const EdgeInsets.all(GrowthSpacing.lg),
      children: [
        // 层级面包屑 + 掌握度旗标（点按切换）
        Row(
          children: [
            Expanded(
              child: data.breadcrumb.isEmpty
                  ? Text('未分类', style: Theme.of(context).textTheme.bodySmall)
                  : Text(
                      data.breadcrumb.breadcrumb,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: GrowthColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            MasteryFlag(
              level: q.masteryLevel,
              onTap: () => onCycleMastery(q.masteryLevel),
            ),
          ],
        ),
        const SizedBox(height: GrowthSpacing.md),

        // 原图 / 题干 分段切换（有图即可切换）
        if (hasImage)
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('原图')),
              ButtonSegment(value: 1, label: Text('题干')),
            ],
            selected: {segment},
            onSelectionChanged: (s) => onSegment(s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? GrowthColors.primary
                    : GrowthColors.primary.withValues(alpha: 0.08),
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : GrowthColors.primary,
              ),
            ),
          ),
        const SizedBox(height: GrowthSpacing.md),

        // 原图（点按缩放）
        if (segment == 0 && hasImage)
          GlassCard(
            padding: const EdgeInsets.all(GrowthSpacing.sm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GrowthRadii.icon),
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.file(File(q.imagePath!), fit: BoxFit.contain),
              ),
            ),
          ),

        // 「题干」视图 = 图片 +（若有）文字；占位文案禁入详情
        if (segment == 1 || !hasImage) ...[
          if (hasImage) ...[
            GlassCard(
              padding: const EdgeInsets.all(GrowthSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GrowthRadii.icon),
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.file(File(q.imagePath!), fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: GrowthSpacing.sm),
          ],
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GrowthSectionHeader(title: '题干'),
                const SizedBox(height: GrowthSpacing.sm),
                if (q.stem.isNotEmpty && !q.stem.startsWith('（图片题'))
                  Text(q.stem, style: Theme.of(context).textTheme.bodyMedium)
                else
                  Text(
                    hasImage ? '题目内容见上图' : '暂无题干文字',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if ((q.answer ?? '').isNotEmpty) ...[
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthSectionHeader(title: '答案'),
                  const SizedBox(height: GrowthSpacing.sm),
                  Text(q.answer!,
                      style: Theme.of(context).textTheme.titleLarge),
                ],
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthSectionHeader(title: '步骤'),
                  const SizedBox(height: GrowthSpacing.sm),
                  for (final (i, s) in steps.indexed) ...[
                    Text('${i + 1}. $s',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: GrowthSpacing.xs),
                  ],
                ],
                if ((q.errorCause ?? '').isNotEmpty) ...[
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthSectionHeader(title: '错因'),
                  const SizedBox(height: GrowthSpacing.sm),
                  Text(q.errorCause!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: GrowthSpacing.md),

        // 操作仅留举一反三（Part 5 入口守卫）
        GrowthButton(
          label: '举一反三',
          icon: Icons.lightbulb_outline_rounded,
          expanded: true,
          onPressed: () => _openExercises(context, ref),
        ),
        const SizedBox(height: GrowthSpacing.xl),
      ],
    );
  }

  /// Part 5.1 入口守卫：无知识点 → 提示先添加
  void _openExercises(BuildContext context, WidgetRef ref) {
    if (data.breadcrumb.isEmpty) {
      AppToast.info(context, '这道题还没有知识点，先在保存页添加，才能按知识点找练习');
      return;
    }
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: _ExercisePanel(
            question: data.question, breadcrumb: data.breadcrumb),
      ),
    );
  }
}

/// 举一反三面板（Part 5：L1 优先 + 来源标签 + L4 文本模型兜底）
class _ExercisePanel extends ConsumerStatefulWidget {
  const _ExercisePanel({required this.question, required this.breadcrumb});

  final QuestionRecord question;
  final KnowledgePath breadcrumb;

  @override
  ConsumerState<_ExercisePanel> createState() => _ExercisePanelState();
}

class _ExercisePanelState extends ConsumerState<_ExercisePanel> {
  List<ExerciseItem> _items = const [];
  bool _generating = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final bankRepo = ref.read(questionBankRepositoryProvider);

      // L0：内置真题库（GAOKAO-Bench 真实高考题，最优先，离线可用）
      final examItems = <ExerciseItem>[];
      final subject = widget.question.subject;
      if (subject.isNotEmpty) {
        final keywords = <String>[
          widget.breadcrumb.point,
          widget.breadcrumb.lesson,
          widget.breadcrumb.chapter,
        ].where((k) => k.isNotEmpty).toList();
        final found = await ExamBankRepository.search(
          subject: subject,
          keywords: keywords,
          excludeStem: widget.question.stem,
          limit: 2,
        );
        examItems.addAll(found.map((q) => ExerciseItem(
              difficulty: '真题',
              question: q.stem,
              options: q.options,
              answer: q.answer,
              explanation: q.explanation,
              sourceLevel: ExerciseSourceLevel.l2Cited,
              sourceLabel: q.sourceLabel,
            )));
      }

      // L1：按 point+chapter 检索个人真题库（未用优先）
      final links = await (db.select(db.questionKnowledgeLinks)
            ..where((t) => t.questionId.equals(widget.question.id)))
          .get();
      final l1Items = <ExerciseItem>[];
      final usedIds = <String>[];
      for (final link in links) {
        final found = await bankRepo.searchL1(
          knowledgePointId: link.knowledgePointId,
          limit: 3,
        );
        found.removeWhere((e) =>
            e.question.trim() == widget.question.stem.trim() &&
            e.question.trim().isNotEmpty);
        for (final item in found) {
          if (l1Items.length >= 3) break;
          l1Items.add(item);
          if (item.bankId != null) usedIds.add(item.bankId!);
        }
        if (l1Items.length >= 3) break;
      }
      await bankRepo.markUsed(usedIds);

      List<ExerciseItem> typed = [...examItems, ...l1Items].take(3).toList();

      // AI 未配置：内置真题库 + 个人题库离线可用
      final gateway = await ref.read(aiGatewayProvider.future);
      if (gateway == null) {
        if (typed.isEmpty) {
          setState(
              () => _error = '该科目暂无内置真题，你的题库也没有同知识点题目。配置 AI 服务商后可解锁 AI 拟题。');
        } else {
          await ref
              .read(exerciseRepositoryProvider)
              .createForQuestion(widget.question.id, typed);
          setState(() => _items = typed);
        }
        return;
      }

      // L1 不足 → L2/L3/L4（L4 对任意文本模型可用，不依赖视觉）
      if (typed.length < 2) {
        final detail = QuestionRepository.decodeAnalysisDetail(
            widget.question.analysisDetail);
        final kps = (detail['knowledgePoints'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
        try {
          final generated = await ref.read(exerciseGeneratorProvider).generate(
                stem: widget.question.stem,
                answer: widget.question.answer ?? '',
                steps: QuestionRepository.decodeSteps(widget.question.keySteps),
                mistakeReason: widget.question.errorCause ?? '',
                knowledgePoints: kps,
              );
          final aiItems = generated.cast<ExerciseItem>();
          for (final item in aiItems) {
            await bankRepo.ingestExercise(
              item: item,
              knowledgePointId:
                  links.isEmpty ? null : links.first.knowledgePointId,
              subject: widget.question.subject,
            );
          }
          typed = [...typed, ...aiItems].take(3).toList();
        } catch (e) {
          if (typed.isEmpty) {
            setState(() => _error = 'AI 生成失败：$e');
          }
        }
      }

      if (typed.isEmpty) {
        setState(() => _error ??= '暂无可用练习题');
      } else {
        await ref
            .read(exerciseRepositoryProvider)
            .createForQuestion(widget.question.id, typed);
        setState(() => _items = typed);
      }
    } catch (e) {
      setState(() => _error = '生成失败：$e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('举一反三', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: GrowthSpacing.xs),
        Text(
          '按「${widget.breadcrumb.breadcrumb}」找同类题',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: GrowthSpacing.md),
        if (_items.isEmpty)
          Expanded(
            child: Center(
              child: _generating
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: GrowthSpacing.lg),
                            child: Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: GrowthSpacing.md),
                        ],
                        GrowthButton(
                          label: _error == null ? '生成练习题' : '重试',
                          icon: Icons.auto_awesome_rounded,
                          onPressed: _generate,
                        ),
                      ],
                    ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: GrowthSpacing.md),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GrowthChip(
                            label: _items[i].difficulty.isEmpty
                                ? '练习 ${i + 1}'
                                : _items[i].difficulty,
                            color: GrowthColors.primary,
                          ),
                          const SizedBox(width: GrowthSpacing.xs),
                          // 来源标签必显（Part 5）
                          GrowthChip(
                            label: _items[i].displaySourceLabel,
                            color: switch (_items[i].sourceLevel) {
                              ExerciseSourceLevel.l1Personal =>
                                GrowthColors.success,
                              ExerciseSourceLevel.l2Cited =>
                                GrowthColors.learning,
                              ExerciseSourceLevel.l3Unverified =>
                                GrowthColors.warning,
                              ExerciseSourceLevel.l4Generated =>
                                GrowthColors.abilityRecovery,
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: GrowthSpacing.sm),
                      Text(_items[i].question,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: GrowthSpacing.sm),
                      for (final opt in _items[i].options) ...[
                        Text(opt, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: GrowthSpacing.xs),
                      ],
                      const SizedBox(height: GrowthSpacing.sm),
                      Text(
                        '答案：${_items[i].answer}\n${_items[i].explanation}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: GrowthColors.success,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
