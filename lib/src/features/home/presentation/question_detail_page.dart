import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_message.dart';
import '../../../core/ai/prompts.dart';
import '../../../core/di/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/question_repository.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/generated_exercise.dart';
import 'package:drift/drift.dart' hide Column, Table;
import '../../learning/learning_providers.dart';

/// 题目详情页：题干/答案/步骤/知识点 + AI 追问 + 举一反三
class QuestionDetailPage extends ConsumerWidget {
  const QuestionDetailPage({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(_questionProvider(questionId));

    return GrowthBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: growthAppBar(
        context,
        title: '错题详情',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: questionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (data) {
          if (data == null) return const GrowthEmptyState(message: '题目不存在');
          return _DetailBody(question: data);
        },
      ),
    ));
  }
}

final _questionProvider = FutureProvider.autoDispose
    .family<QuestionRecord?, String>(
        (ref, id) => ref.watch(questionRepositoryProvider).get(id));

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.question});

  final QuestionRecord question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = QuestionRepository.decodeSteps(question.keySteps);
    final tags = QuestionRepository.decodeTags(question.tags);
    final detail =
        QuestionRepository.decodeAnalysisDetail(question.analysisDetail);
    final kps = (detail['knowledgePoints'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final advice = (detail['studyAdvice'] ?? '').toString();

    return ListView(
      padding: const EdgeInsets.all(GrowthSpacing.lg),
      children: [
        Row(
          children: [
            GrowthChip(label: question.subject),
            const SizedBox(width: GrowthSpacing.sm),
            for (final t in tags.take(3)) ...[
              GrowthChip(label: t, color: GrowthColors.abilityPersistence),
              const SizedBox(width: GrowthSpacing.xs),
            ],
          ],
        ),
        const SizedBox(height: GrowthSpacing.md),
        GrowthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GrowthSectionHeader(title: '题干'),
              const SizedBox(height: GrowthSpacing.sm),
              Text(question.stem,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: GrowthSpacing.md),
        GrowthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GrowthSectionHeader(title: '答案与步骤'),
              const SizedBox(height: GrowthSpacing.sm),
              Text(question.answer ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: GrowthSpacing.sm),
              for (final (i, s) in steps.indexed) ...[
                Text('${i + 1}. $s',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: GrowthSpacing.xs),
              ],
            ],
          ),
        ),
        if ((question.errorCause ?? '').isNotEmpty) ...[
          const SizedBox(height: GrowthSpacing.md),
          GrowthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GrowthSectionHeader(title: '错因'),
                const SizedBox(height: GrowthSpacing.sm),
                Text(question.errorCause!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        if (kps.isNotEmpty) ...[
          const SizedBox(height: GrowthSpacing.md),
          GrowthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GrowthSectionHeader(title: '知识点'),
                const SizedBox(height: GrowthSpacing.sm),
                for (final kp in kps) ...[
                  Text('· $kp', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: GrowthSpacing.xs),
                ],
              ],
            ),
          ),
        ],
        if (advice.isNotEmpty) ...[
          const SizedBox(height: GrowthSpacing.md),
          GrowthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GrowthSectionHeader(title: '学习建议'),
                const SizedBox(height: GrowthSpacing.sm),
                Text(advice, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        const SizedBox(height: GrowthSpacing.lg),
        GrowthButton(
          label: '问 MOSS 伴读',
          icon: Icons.chat_bubble_outline_rounded,
          variant: GrowthButtonVariant.secondary,
          expanded: true,
          onPressed: () => _openFollowUp(context, ref),
        ),
        const SizedBox(height: GrowthSpacing.sm),
        GrowthButton(
          label: '举一反三',
          icon: Icons.lightbulb_outline_rounded,
          expanded: true,
          onPressed: () => _openExercises(context, ref),
        ),
        const SizedBox(height: GrowthSpacing.sm),
        GrowthButton(
          label: '专注攻克这道题',
          icon: Icons.self_improvement_rounded,
          variant: GrowthButtonVariant.secondary,
          expanded: true,
          onPressed: () => context.push('/focus?questionId=${question.id}'),
        ),
      ],
    );
  }

  void _openFollowUp(BuildContext context, WidgetRef ref) {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _FollowUpPanel(question: question),
      ),
    );
  }

  void _openExercises(BuildContext context, WidgetRef ref) {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: _ExercisePanel(question: question),
      ),
    );
  }
}

/// AI 追问面板（流式输出）
class _FollowUpPanel extends ConsumerStatefulWidget {
  const _FollowUpPanel({required this.question});

  final QuestionRecord question;

  @override
  ConsumerState<_FollowUpPanel> createState() => _FollowUpPanelState();
}

class _FollowUpPanelState extends ConsumerState<_FollowUpPanel> {
  final _controller = TextEditingController();
  final _history = <AiMessage>[];
  String _streaming = '';
  bool _busy = false;

  String get _context => AiPrompts.followUpContext(
        stem: widget.question.stem,
        answer: widget.question.answer ?? '',
        steps: QuestionRepository.decodeSteps(widget.question.keySteps),
        mistakeReason: widget.question.errorCause ?? '',
        knowledgePoints: const [],
      );

  Future<void> _ask() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _busy = true;
      _streaming = '';
      _history.add(AiMessage(role: 'user', content: q));
    });

    // 持久化用户消息
    await _persistMessage(q, 'user');

    final buffer = StringBuffer();
    try {
      await for (final delta in ref.read(followUpStreamProvider).ask(
            questionContext: _context,
            history: _history.sublist(0, _history.length - 1),
            question: q,
          )) {
        buffer.write(delta);
        if (mounted) setState(() => _streaming = buffer.toString());
      }
    } catch (e) {
      buffer.write('\n（回答中断：$e）');
      if (mounted) setState(() => _streaming = buffer.toString());
    }

    _history.add(AiMessage(role: 'assistant', content: buffer.toString()));
    await _persistMessage(buffer.toString(), 'assistant');
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _persistMessage(String content, String role) async {
    final db = ref.read(databaseProvider);
    await db.into(db.aiMessages).insert(
          AiMessagesCompanion.insert(
            questionId: Value(widget.question.id),
            role: role,
            content: content,
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = ref.read(databaseProvider);
    final rows = await (db.select(db.aiMessages)
          ..where((t) => t.questionId.equals(widget.question.id))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    if (!mounted) return;
    setState(() {
      _history
        ..clear()
        ..addAll(rows.map((r) => AiMessage(role: r.role, content: r.content)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('MOSS 伴读 · 围绕本题答疑', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: GrowthSpacing.md),
        Expanded(
          child: ListView.builder(
            itemCount: _history.length + (_streaming.isNotEmpty ? 1 : 0),
            itemBuilder: (context, i) {
              final isStreaming = i == _history.length;
              final msg = isStreaming
                  ? AiMessage(role: 'assistant', content: _streaming)
                  : _history[i];
              final mine = msg.role == 'user';
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: GrowthSpacing.sm),
                  padding: const EdgeInsets.all(GrowthSpacing.md),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: mine
                        ? GrowthColors.primary.withValues(alpha: 0.16)
                        : GrowthColors.glassLight,
                    borderRadius: BorderRadius.circular(GrowthRadii.field),
                  ),
                  child: Text(msg.content,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GrowthTextField(
                controller: _controller,
                hint: '关于这道题，你还想问…',
                onSubmitted: (_) => _ask(),
              ),
            ),
            const SizedBox(width: GrowthSpacing.sm),
            GrowthButton(
              label: '发送',
              loading: _busy,
              onPressed: _ask,
            ),
          ],
        ),
      ],
    );
  }
}

/// 举一反三面板
class _ExercisePanel extends ConsumerStatefulWidget {
  const _ExercisePanel({required this.question});

  final QuestionRecord question;

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

      // L1：个人真题库同知识点检索（库内同知识点真题 ≥2 道时必须命中）
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
        // 排除当前题目自身
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

      List<ExerciseItem> typed = l1Items;

      // AI 未配置：仅 L1 离线可用 + 解锁引导（Part 3.4）
      final gateway = await ref.read(aiGatewayProvider.future);
      if (gateway == null) {
        if (typed.isEmpty) {
          setState(() => _error = '题库里还没有同知识点的真题。配置 AI 服务商后，可解锁 AI 真题引用与拟题。');
        } else {
          await ref
              .read(exerciseRepositoryProvider)
              .createForQuestion(widget.question.id, typed);
          setState(() => _items = typed);
        }
        return;
      }

      // L1 不足时用 AI 补齐（L2 引用 / L3 待核实 / L4 拟题，均带来源标签）
      if (typed.length < 2) {
        final detail = QuestionRepository.decodeAnalysisDetail(
            widget.question.analysisDetail);
        final kps = (detail['knowledgePoints'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
        final generated = await ref.read(exerciseGeneratorProvider).generate(
              stem: widget.question.stem,
              answer: widget.question.answer ?? '',
              steps: QuestionRepository.decodeSteps(widget.question.keySteps),
              mistakeReason: widget.question.errorCause ?? '',
              knowledgePoints: kps,
            );
        final aiItems = generated.cast<ExerciseItem>();
        // AI 生成的题也入题库（飞轮）
        for (final item in aiItems) {
          await bankRepo.ingestExercise(
            item: item,
            knowledgePointId:
                links.isEmpty ? null : links.first.knowledgePointId,
          );
        }
        typed = [...typed, ...aiItems].take(3).toList();
      }

      if (typed.isEmpty) {
        setState(() => _error = '暂无可用练习：题库没有同知识点真题，AI 也没生成出合格题目');
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
                          Text(_error!,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center),
                          const SizedBox(height: GrowthSpacing.md),
                        ],
                        GrowthButton(
                          label: '生成练习题',
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
                child: GrowthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GrowthChip(
                            label: _items[i].difficulty.isEmpty
                                ? '练习 ${i + 1}'
                                : _items[i].difficulty,
                            color: GrowthColors.abilityFocus,
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
