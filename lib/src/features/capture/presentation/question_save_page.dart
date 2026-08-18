import 'dart:io';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/bridge/scanner_bridge.dart';
import '../../../core/di/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/subject.dart';
import '../../learning/learning_providers.dart';

const _uuid = Uuid();

/// 题目保存页（Part 3 核心原则）：
/// AI 绝不生成题干/答案/错因等解析内容——解析由用户手动填写或直接保存原图。
/// AI 仅提供知识点标签供确认或修改。
class QuestionSavePage extends ConsumerStatefulWidget {
  const QuestionSavePage({super.key, required this.path, required this.source});

  final String path;
  final CaptureSource source;

  @override
  ConsumerState<QuestionSavePage> createState() => _QuestionSavePageState();
}

class _QuestionSavePageState extends ConsumerState<QuestionSavePage> {
  final _stemController = TextEditingController();
  final _answerController = TextEditingController();
  final _mistakeController = TextEditingController();

  String _subject = Subject.other.label;
  List<String> _tags = [];
  bool _tagLoading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  /// Part 3.1：AI 仅输出知识点标签
  Future<void> _fetchTags() async {
    setState(() => _tagLoading = true);
    try {
      final gateway = await ref.read(aiGatewayProvider.future);
      if (gateway == null) {
        if (mounted) setState(() => _tagLoading = false);
        return;
      }
      final bytes = await File(widget.path).readAsBytes();
      final tags = await gateway.suggestKnowledgeTags(imageBytes: bytes);
      if (mounted) {
        setState(() {
          _tags = tags;
          _tagLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _tagLoading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final qid = _uuid.v4();

      // 1) 题目入库（原图 + 用户手填内容，无 AI 生成的解析）
      await db.into(db.questionRecords).insert(
            QuestionRecordsCompanion.insert(
              id: qid,
              subject: Value(_subject),
              imagePath: Value(widget.path),
              stem: Value(_stemController.text.trim().isEmpty
                  ? '（图片题，未填写题干）'
                  : _stemController.text.trim()),
              answer: Value(_answerController.text.trim().isEmpty
                  ? null
                  : _answerController.text.trim()),
              errorCause: Value(_mistakeController.text.trim().isEmpty
                  ? null
                  : _mistakeController.text.trim()),
              tags: Value('[${_tags.map((t) => '"$t"').join(',')}]'),
              contentStatus: const Value('saved'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 2) 知识点沉淀 + 关联（用户确认的标签）
      String? firstKpId;
      for (final tag in _tags) {
        final existing = await (db.select(db.knowledgePoints)
              ..where((t) => t.subject.equals(_subject) & t.name.equals(tag)))
            .get();
        final kpId = existing.isEmpty ? _uuid.v4() : existing.first.id;
        if (existing.isEmpty) {
          await db.into(db.knowledgePoints).insert(
                KnowledgePointsCompanion.insert(
                  id: kpId,
                  name: tag,
                  subject: Value(_subject),
                  firstSeenAt: now,
                ),
              );
        }
        firstKpId ??= kpId;
        await db.into(db.questionKnowledgeLinks).insert(
              QuestionKnowledgeLinksCompanion.insert(
                questionId: qid,
                knowledgePointId: kpId,
              ),
            );
      }

      // 3) 题库飞轮：用户真题入库
      await ref.read(questionBankRepositoryProvider).ingestUserQuestion(
            questionId: qid,
            stem: _stemController.text.trim(),
            knowledgePointId: firstKpId,
          );

      // 4) FSRS 复习卡
      await db.into(db.reviewCards).insert(
            ReviewCardsCompanion.insert(
              id: _uuid.v4(),
              questionId: qid,
              due: now,
              createdAt: now,
            ),
          );

      // 5) 学习事件
      await db.into(db.learningEvents).insert(
            LearningEventsCompanion.insert(
              eventType: 'question_saved',
              questionId: Value(qid),
              at: now,
              payload: Value('{"source":"${widget.source.name}"}'),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到错题本')),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _stemController.dispose();
    _answerController.dispose();
    _mistakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: growthAppBar(
        context,
        title: '保存题目',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: GrowthBackground(
        child: ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            // 原图预览（扫描件）
            GlassCard(
              padding: const EdgeInsets.all(GrowthSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GrowthRadii.icon),
                child: Image.file(
                  File(widget.path),
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),

            // 科目
            Text('科目', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: GrowthSpacing.sm),
            Wrap(
              spacing: GrowthSpacing.sm,
              runSpacing: GrowthSpacing.sm,
              children: [
                for (final s in Subject.values)
                  GrowthChip(
                    label: s.label,
                    selected: _subject == s.label,
                    onTap: () => setState(() => _subject = s.label),
                  ),
              ],
            ),
            const SizedBox(height: GrowthSpacing.md),

            // AI 知识点标签（仅标签，供确认/修改）
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GrowthSectionHeader(
                    title: '知识点标签',
                    trailing: TextButton(
                      onPressed: _tagLoading ? null : _fetchTags,
                      child: const Text('重新识别'),
                    ),
                  ),
                  const SizedBox(height: GrowthSpacing.xs),
                  Text(
                    'AI 仅提供标签建议，点击可移除；解析内容由你填写',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: GrowthSpacing.sm),
                  if (_tagLoading)
                    const Padding(
                      padding: EdgeInsets.all(GrowthSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_tags.isEmpty)
                    Text(
                      '未识别到标签（未配置 AI 或识别失败），可跳过',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: GrowthSpacing.sm,
                      runSpacing: GrowthSpacing.sm,
                      children: [
                        for (final tag in _tags)
                          GrowthChip(
                            label: '$tag ✕',
                            onTap: () => setState(() => _tags.remove(tag)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),

            // 手动填写（解析内容只来自用户）
            GrowthTextField(
              controller: _stemController,
              label: '题干（可留空，直接保存原图）',
              hint: '抄录或简述题目…',
              maxLines: 3,
            ),
            const SizedBox(height: GrowthSpacing.md),
            GrowthTextField(
              controller: _answerController,
              label: '答案（选填）',
              hint: '正确答案…',
              maxLines: 2,
            ),
            const SizedBox(height: GrowthSpacing.md),
            GrowthTextField(
              controller: _mistakeController,
              label: '错因（选填）',
              hint: '当时为什么错了…',
              maxLines: 2,
            ),
            const SizedBox(height: GrowthSpacing.lg),
            GrowthButton(
              label: '保存到错题本',
              icon: Icons.check_rounded,
              expanded: true,
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: GrowthSpacing.xl),
          ],
        ),
      ),
    );
  }
}
