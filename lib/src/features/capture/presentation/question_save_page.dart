import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ai/ai_call.dart';
import '../../../core/bridge/scanner_bridge.dart';
import 'taxonomy_selector.dart';
import '../../../core/di/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/knowledge_path.dart';
import '../../../domain/models/subject.dart';
import '../../learning/learning_providers.dart';

const _uuid = Uuid();

/// 题目保存页（v15 终版）：
/// 硬门 1：保存的图片是处理后的归档图（路径来自编辑屏），绝不存原图路径
/// 硬门 2：**图片即题干** —— 不再使用"（图片题，未填写题干）"占位文案
/// 硬门 3：层级知识点 subject/version/book/chapter/lesson/point，
///         AI 输出完整层级（version 可推断必须可改），视觉守卫禁转圈，
///         手动级联 + 历史值自动补全
/// 科目必选（未选禁保存）
class QuestionSavePage extends ConsumerStatefulWidget {
  const QuestionSavePage({
    super.key,
    required this.path,
    required this.source,
    this.cropSource = 'original',
  });

  final String path;
  final CaptureSource source;

  /// manual=用户框选裁剪 / auto=自动校准 / original=原图
  final String cropSource;

  @override
  ConsumerState<QuestionSavePage> createState() => _QuestionSavePageState();
}

class _QuestionSavePageState extends ConsumerState<QuestionSavePage> {
  final _stemController = TextEditingController();
  final _answerController = TextEditingController();
  final _mistakeController = TextEditingController();

  /// 科目必选（v13 4.1）：null = 未选，保存前必须选择
  String? _subject;
  String? _subjectError;

  /// 级联选择器选中的知识点（多选）
  List<String> _selectedPoints = const [];

  bool _saving = false;

  // ---- 层级知识点（Part 3.2） ----
  KnowledgePath _path = const KnowledgePath();
  bool _pathLoading = false;
  String? _pathError;
  bool _visionUnsupported = false;

  /// 推荐的视觉模型名（null = 未推荐/未找到）
  String? _recommendedVisionModel;

  @override
  void initState() {
    super.initState();
    _fetchPath();
  }

  /// AI 识别层级路径（视觉守卫：不支持→推荐视觉模型+一键换用，禁转圈）
  Future<void> _fetchPath() async {
    setState(() {
      _pathLoading = true;
      _pathError = null;
      _visionUnsupported = false;
      _recommendedVisionModel = null;
    });
    try {
      final gateway = await ref.read(aiGatewayProvider.future);
      if (gateway == null) {
        // 未配置 AI：手动模式，不报错
        if (mounted) setState(() => _pathLoading = false);
        return;
      }
      final bytes = await File(widget.path).readAsBytes();
      final path = await gateway.suggestKnowledgePath(imageBytes: bytes);
      if (mounted) {
        setState(() {
          _path = path;
          // AI 推断学科仅在未手动选择时作为默认
          if (path.subject.isNotEmpty && _subject == null) {
            _subject = Subject.values.any((s) => s.label == path.subject)
                ? path.subject
                : null;
          }
          _pathLoading = false;
        });
      }
    } on AiCallException catch (e) {
      if (!mounted) return;
      setState(() {
        _pathLoading = false;
        if (e.tier == AiErrorTier.visionUnsupported) {
          _visionUnsupported = true; // 视觉守卫：明确提示，禁转圈
          unawaited(_suggestVisionModel());
        } else {
          _pathError = e.userMessage;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _pathLoading = false;
          _pathError = '识别失败：$e';
        });
      }
    }
  }

  /// 从当前服务商拉取模型列表，推荐一个视觉模型
  Future<void> _suggestVisionModel() async {
    try {
      final repo = ref.read(aiProviderRepositoryProvider);
      final config = await repo.defaultProvider();
      if (config == null) return;
      final client = await repo.buildClient(config.id);
      if (client == null) return;
      final models = await client.fetchModels();
      const visionKeywords = [
        'vision', 'vl', '4o', 'multimodal', 'image', 'eye',
        'gpt-4o', 'claude-3', 'gemini', 'qwen-vl', 'qwen2-vl',
        'glm-4v', 'step-1v', 'yi-vl', 'llava',
      ];
      final visionModels = models.where((m) {
        final lower = m.toLowerCase();
        return visionKeywords.any((k) => lower.contains(k));
      }).toList();
      if (visionModels.isNotEmpty && mounted) {
        setState(() => _recommendedVisionModel = visionModels.first);
      }
    } catch (_) {}
  }

  /// 一键换用推荐的视觉模型
  Future<void> _switchToVisionModel() async {
    final model = _recommendedVisionModel;
    if (model == null) return;
    try {
      final db = ref.read(databaseProvider);
      final repo = ref.read(aiProviderRepositoryProvider);
      final config = await repo.defaultProvider();
      if (config == null) return;
      await (db.update(db.aiProviders)..where((t) => t.id.equals(config.id)))
          .write(AiProvidersCompanion(model: Value(model)));
      ref.invalidate(aiGatewayProvider);
      if (mounted) {
        setState(() {
          _visionUnsupported = false;
          _recommendedVisionModel = null;
        });
        AppToast.success(context, '已切换到 $model，正在重新识别…');
        unawaited(_fetchPath());
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '切换失败：$e');
    }
  }

  /// 级联选择器（学科→册→章→节→知识点，历史置顶+自定义兜底+多选）
  void _openPathEditor() {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => TaxonomySelectorSheet(
        initialSubject: _subject ?? '',
        onConfirm: (sel) {
          setState(() {
            _path = KnowledgePath(
              subject: sel.subject,
              version: sel.version,
              book: sel.book,
              chapter: sel.chapter,
              lesson: sel.lesson,
              point: sel.points.isNotEmpty ? sel.points.join('、') : '',
            );
            _selectedPoints = sel.points;
            if (sel.subject.isNotEmpty) _subject = sel.subject;
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    // 科目必选校验（v13 4.1）
    if (_subject == null) {
      setState(() => _subjectError = '请先选择科目，科目驱动列表、统计与导出');
      return;
    }
    setState(() { _subjectError = null; _saving = true; });
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final qid = _uuid.v4();

      // v15 终版：**图片即题干**
      // 题干字段仅在有真实文字填写时存值；无文字时留空或存空串，
      // UI 展示时直接显示题目图片作为题干。
      // 彻底禁止"（图片题，未填写题干）"占位文案。
      final stemText = _stemController.text.trim();

      await db.into(db.questionRecords).insert(
            QuestionRecordsCompanion.insert(
              id: qid,
              subject: Value(_subject!),
              imagePath: Value(widget.path),
              stem: Value(stemText.isEmpty ? '' : stemText),
              answer: Value(_answerController.text.trim().isEmpty
                  ? null : _answerController.text.trim()),
              errorCause: Value(_mistakeController.text.trim().isEmpty
                  ? null : _mistakeController.text.trim()),
              tags: Value(_buildTagsJson()),
              analysisDetail: Value('{"cropSource":"${widget.cropSource}"}'),
              contentStatus: const Value('saved'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 层级知识点入库 + 关联（多知识点逐个写入）
      if (!_path.isEmpty || (_subject ?? '').isNotEmpty) {
        await _saveKnowledgePoints(db, qid, now);
      }

      // 题库飞轮：用户真题入库
      await ref.read(questionBankRepositoryProvider).ingestUserQuestion(
            questionId: qid,
            stem: _stemController.text.trim(),
            knowledgePointId: null,
            subject: _subject ?? '',
          );

      // SM-2 复习卡（新卡初始状态）
      await db.into(db.reviewCards).insert(
            ReviewCardsCompanion.insert(
              id: _uuid.v4(),
              questionId: qid,
              reps: const Value(0),
              easinessFactor: const Value(2.5),
              intervalDays: const Value(0),
              due: now,
              createdAt: now,
            ),
          );

      // 学习事件
      await db.into(db.learningEvents).insert(
            LearningEventsCompanion.insert(
              eventType: 'question_saved',
              questionId: Value(qid),
              at: now,
              payload: Value(
                  '{"source":"${widget.source.name}","cropSource":"${widget.cropSource}"}'),
            ),
          );

      await ref.read(backupStateProvider).markDirty();
      if (mounted) {
        unawaited(HapticFeedback.mediumImpact());
        AppToast.success(context, '已保存到错题本');
        context.go('/');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _buildTagsJson() {
    final tags = <String>[
      if ((_subject ?? '').isNotEmpty && _subject != Subject.other.label) _subject!,
      if (_path.point.isNotEmpty) _path.point,
      if (_path.chapter.isNotEmpty) _path.chapter,
    ];
    return '[${tags.map((t) => '"$t"').join(',')}]';
  }

  /// 多知识点写入：级联选中的每个知识点各建一条（含完整层级路径）
  Future<void> _saveKnowledgePoints(AppDatabase db, String qid, DateTime now) async {
    final subject = _subject ?? '';
    final names = _selectedPoints.isNotEmpty
        ? _selectedPoints
        : (_path.leafName.isNotEmpty ? [_path.leafName] : <String>[]);
    if (names.isEmpty && subject.isNotEmpty) {
      names.add(subject);
    }
    for (final name in names) {
      if (name.isEmpty) continue;
      final existing = await (db.select(db.knowledgePoints)
            ..where((t) => t.subject.equals(subject) & t.name.equals(name)))
          .get();
      final kpId = existing.isEmpty ? _uuid.v4() : existing.first.id;
      if (existing.isEmpty) {
        await db.into(db.knowledgePoints).insert(
              KnowledgePointsCompanion.insert(
                id: kpId,
                name: name,
                subject: Value(subject),
                version: Value(_path.version),
                book: Value(_path.book),
                chapter: Value(_path.chapter),
                lesson: Value(_path.lesson),
                firstSeenAt: now,
              ),
            );
      }
      await db.into(db.questionKnowledgeLinks).insert(
            QuestionKnowledgeLinksCompanion.insert(
              questionId: qid,
              knowledgePointId: kpId,
            ),
          );
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
            // 原图预览（处理后的归档图）
            GlassCard(
              padding: const EdgeInsets.all(GrowthSpacing.sm),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GrowthRadii.icon),
                    child: Image.file(
                      File(widget.path),
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: GrowthSpacing.xs),
                  Text(
                    switch (widget.cropSource) {
                      'manual' => '已按你的框选裁剪保存',
                      'auto' => '已自动提取纸面并拉正',
                      _ => '使用原始图片',
                    },
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),

            // 科目（必选，v13 4.1）
            Text('科目（必选）', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: GrowthSpacing.sm),
            Wrap(
              spacing: GrowthSpacing.sm,
              runSpacing: GrowthSpacing.sm,
              children: [
                for (final s in Subject.values)
                  GrowthChip(
                    label: s.label,
                    selected: _subject == s.label,
                    onTap: () => setState(() {
                      _subject = s.label;
                      _subjectError = null;
                    }),
                  ),
              ],
            ),
            if (_subjectError != null) ...[
              const SizedBox(height: GrowthSpacing.xs),
              Text(
                _subjectError!,
                style: TextStyle(fontSize: 12, color: GrowthColors.warning),
              ),
            ],
            const SizedBox(height: GrowthSpacing.md),

            // ---- 题干（选填，图片即题干） ----
            Text('题干（选填，有图可不填）', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: GrowthSpacing.sm),
            GrowthTextField(
              controller: _stemController,
              label: '题干文字（可选，图片即题干）',
              maxLines: 3,
              hint: '如需补充文字说明可在此填写',
            ),
            const SizedBox(height: GrowthSpacing.md),

            // ---- 答案（选填） ----
            Text('答案（选填）', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: GrowthSpacing.sm),
            GrowthTextField(
              controller: _answerController,
              label: '答案',
              maxLines: 2,
              hint: '复习时可对照查看',
            ),
            const SizedBox(height: GrowthSpacing.md),

            // ---- 错因（选填） ----
            Text('错因（选填）', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: GrowthSpacing.sm),
            GrowthTextField(
              controller: _mistakeController,
              label: '错因分析',
              maxLines: 2,
              hint: '帮助后续复习定位薄弱点',
            ),
            const SizedBox(height: GrowthSpacing.md),

            // ---- 层级知识点（硬门 3） ----
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GrowthSectionHeader(
                    title: '知识点层级',
                    trailing: TextButton(
                      onPressed: _pathLoading ? null : _openPathEditor,
                      child: const Text('手动编辑'),
                    ),
                  ),
                  const SizedBox(height: GrowthSpacing.xs),
                  if (_pathLoading)
                    const Padding(
                      padding: EdgeInsets.all(GrowthSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_visionUnsupported)
                    // 视觉守卫：推荐视觉模型+一键换用，禁转圈
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前模型不支持图片理解，无法自动识别知识点。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: GrowthSpacing.sm),
                        if (_recommendedVisionModel != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '检测到视觉模型「$_recommendedVisionModel」，可一键换用：',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: GrowthColors.learning),
                              ),
                              const SizedBox(height: GrowthSpacing.xs),
                              GrowthButton(
                                label: '换用 $_recommendedVisionModel 并重新识别',
                                onPressed: _switchToVisionModel,
                              ),
                              const SizedBox(height: GrowthSpacing.sm),
                            ],
                          )
                        else
                          Text(
                            '可在「设置 → AI 服务商」换用带视觉能力的模型，或直接手动填写。',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: GrowthSpacing.sm),
                        GrowthButton(
                          label: '手动填写知识点',
                          variant: GrowthButtonVariant.secondary,
                          onPressed: _openPathEditor,
                        ),
                      ],
                    )
                  else if (_pathError != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_pathError!, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: GrowthSpacing.sm),
                        Row(
                          children: [
                            GrowthButton(
                              label: '重新识别',
                              variant: GrowthButtonVariant.secondary,
                              onPressed: _fetchPath,
                            ),
                            const SizedBox(width: GrowthSpacing.sm),
                            GrowthButton(
                              label: '手动填写',
                              variant: GrowthButtonVariant.ghost,
                              onPressed: _openPathEditor,
                            ),
                          ],
                        ),
                      ],
                    )
                  else if (_path.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '未配置 AI 或未识别到——手动填写同样可用',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: GrowthSpacing.sm),
                        GrowthButton(
                          label: '手动填写知识点',
                          variant: GrowthButtonVariant.secondary,
                          onPressed: _openPathEditor,
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 面包屑
                        Wrap(
                          spacing: GrowthSpacing.xs,
                          runSpacing: GrowthSpacing.xs,
                          children: [
                            for (final seg in [
                              _path.subject,
                              _path.version,
                              _path.book,
                              _path.chapter,
                              _path.lesson,
                              _path.point,
                            ])
                              if (seg.isNotEmpty)
                                GrowthChip(label: seg, color: GrowthColors.primary),
                          ],
                        ),
                        const SizedBox(height: GrowthSpacing.sm),
                        GrowthButton(
                          label: '修改知识点',
                          variant: GrowthButtonVariant.ghost,
                          onPressed: _openPathEditor,
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: GrowthSpacing.xl),

            // 保存按钮
            GrowthButton(
              label: _saving ? '保存中…' : '保存到错题本',
              expanded: true,
              icon: Icons.save_rounded,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: GrowthSpacing.lg),
          ],
        ),
      ),
    );
  }
}
