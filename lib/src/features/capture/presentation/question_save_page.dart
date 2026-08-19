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
import '../../../core/di/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/knowledge_path.dart';
import '../../../domain/models/subject.dart';
import '../../learning/learning_providers.dart';

const _uuid = Uuid();

/// 题目保存页（Part 3）：
/// 硬门 1：保存的图片是处理后的归档图（路径来自编辑屏），绝不存原图路径
/// 硬门 3：层级知识点 subject/version/book/chapter/lesson/point，
///         AI 输出完整层级（version 可推断必须可改），视觉守卫禁转圈，
///         手动级联 + 历史值自动补全
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

  String _subject = Subject.other.label;
  bool _saving = false;

  // ---- 层级知识点（Part 3.2） ----
  KnowledgePath _path = const KnowledgePath();
  bool _pathLoading = false;
  String? _pathError;
  bool _visionUnsupported = false;

  /// 补钉 A：推荐的视觉模型名（null = 未推荐/未找到）
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
          if (path.subject.isNotEmpty) _subject = path.subject;
          _pathLoading = false;
        });
      }
    } on AiCallException catch (e) {
      if (!mounted) return;
      setState(() {
        _pathLoading = false;
        if (e.tier == AiErrorTier.visionUnsupported) {
          _visionUnsupported = true; // 视觉守卫：明确提示，禁转圈
          // 补钉 A：自动从已获取模型列表推荐一个视觉模型
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

  /// 补钉 A：从当前服务商拉取模型列表，推荐一个视觉模型
  Future<void> _suggestVisionModel() async {
    try {
      final repo = ref.read(aiProviderRepositoryProvider);
      final config = await repo.defaultProvider();
      if (config == null) return;
      final client = await repo.buildClient(config.id);
      if (client == null) return;
      final models = await client.fetchModels();
      // 视觉模型关键词匹配
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
    } catch (_) {
      // 静默：推荐失败不影响手动填写
    }
  }

  /// 补钉 A：一键换用推荐的视觉模型
  Future<void> _switchToVisionModel() async {
    final model = _recommendedVisionModel;
    if (model == null) return;
    try {
      final db = ref.read(databaseProvider);
      final repo = ref.read(aiProviderRepositoryProvider);
      final config = await repo.defaultProvider();
      if (config == null) return;
      await (db.update(db.aiProviders)
            ..where((t) => t.id.equals(config.id)))
          .write(AiProvidersCompanion(model: Value(model)));
      // 刷新 gateway provider
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

  /// 手动级联编辑（历史值自动补全）
  void _openPathEditor() {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => _KnowledgePathEditor(
        initial: _path,
        ref: ref,
        onSave: (p) {
          setState(() {
            _path = p;
            if (p.subject.isNotEmpty) _subject = p.subject;
          });
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final qid = _uuid.v4();

      // 硬门 1：入库的是处理后的归档图路径（widget.path 来自编辑屏归档）
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
              tags: Value(_buildTagsJson()),
              analysisDetail: Value('{"cropSource":"${widget.cropSource}"}'),
              contentStatus: const Value('saved'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 层级知识点入库 + 关联
      if (!_path.isEmpty || _subject.isNotEmpty) {
        await _saveKnowledgePoint(db, qid, now);
      }

      // 题库飞轮：用户真题入库
      await ref.read(questionBankRepositoryProvider).ingestUserQuestion(
            questionId: qid,
            stem: _stemController.text.trim(),
            knowledgePointId: null,
            subject: _subject,
          );

      // FSRS 复习卡
      await db.into(db.reviewCards).insert(
            ReviewCardsCompanion.insert(
              id: _uuid.v4(),
              questionId: qid,
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
      if (_subject.isNotEmpty && _subject != Subject.other.label) _subject,
      if (_path.point.isNotEmpty) _path.point,
      if (_path.chapter.isNotEmpty) _path.chapter,
    ];
    return '[${tags.map((t) => '"$t"').join(',')}]';
  }

  Future<void> _saveKnowledgePoint(
    AppDatabase db,
    String qid,
    DateTime now,
  ) async {
    final name = _path.leafName.isNotEmpty ? _path.leafName : _subject;
    if (name.isEmpty) return;
    final existing = await (db.select(db.knowledgePoints)
          ..where((t) => t.subject.equals(_subject) & t.name.equals(name)))
        .get();
    final kpId = existing.isEmpty ? _uuid.v4() : existing.first.id;
    if (existing.isEmpty) {
      await db.into(db.knowledgePoints).insert(
            KnowledgePointsCompanion.insert(
              id: kpId,
              name: name,
              subject: Value(_subject),
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: GrowthColors.learning,
                                    ),
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
                    // 错误态可点重试
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pathError!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                                GrowthChip(
                                  label: seg,
                                  color: seg == _path.point
                                      ? GrowthColors.primary
                                      : GrowthColors.gray5,
                                ),
                          ],
                        ),
                        const SizedBox(height: GrowthSpacing.xs),
                        Text(
                          'AI 识别，version 可推断也可改——点「手动编辑」调整任意层级',
                          style: Theme.of(context).textTheme.bodySmall,
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
              label: '题干（可留空，直接保存图片）',
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

/// 手动级联编辑器（历史值自动补全）
class _KnowledgePathEditor extends ConsumerStatefulWidget {
  const _KnowledgePathEditor({
    required this.initial,
    required this.ref,
    required this.onSave,
  });

  final KnowledgePath initial;
  final WidgetRef ref;
  final ValueChanged<KnowledgePath> onSave;

  @override
  ConsumerState<_KnowledgePathEditor> createState() =>
      _KnowledgePathEditorState();
}

class _KnowledgePathEditorState extends ConsumerState<_KnowledgePathEditor> {
  late final TextEditingController _subject;
  late final TextEditingController _version;
  late final TextEditingController _book;
  late final TextEditingController _chapter;
  late final TextEditingController _lesson;
  late final TextEditingController _point;

  List<KnowledgePoint> _history = const [];

  @override
  void initState() {
    super.initState();
    _subject = TextEditingController(text: widget.initial.subject);
    _version = TextEditingController(text: widget.initial.version);
    _book = TextEditingController(text: widget.initial.book);
    _chapter = TextEditingController(text: widget.initial.chapter);
    _lesson = TextEditingController(text: widget.initial.lesson);
    _point = TextEditingController(text: widget.initial.point);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = widget.ref.read(databaseProvider);
    final rows = await (db.select(db.knowledgePoints)..limit(200)).get();
    if (mounted) setState(() => _history = rows);
  }

  List<String> _distinct(String Function(KnowledgePoint) pick) {
    final seen = <String>{};
    final result = <String>[];
    for (final kp in _history) {
      final v = pick(kp);
      if (v.isNotEmpty && seen.add(v)) result.add(v);
    }
    return result.take(6).toList();
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    List<String> suggestions = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GrowthTextField(
          controller: controller,
          label: label,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: GrowthSpacing.xs),
          Wrap(
            spacing: GrowthSpacing.xs,
            runSpacing: GrowthSpacing.xs,
            children: [
              for (final s in suggestions)
                GrowthChip(
                  label: s,
                  onTap: () => setState(() => controller.text = s),
                ),
            ],
          ),
        ],
        const SizedBox(height: GrowthSpacing.sm),
      ],
    );
  }

  @override
  void dispose() {
    _subject.dispose();
    _version.dispose();
    _book.dispose();
    _chapter.dispose();
    _lesson.dispose();
    _point.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('知识点层级', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: GrowthSpacing.xs),
          Text('从上到下逐级填写，历史值点选即可补全',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: GrowthSpacing.md),
          Expanded(
            child: ListView(
              children: [
                _field(
                  label: '学科',
                  controller: _subject,
                  suggestions: _distinct((kp) => kp.subject),
                ),
                _field(
                  label: '教材版本（如 人教版）',
                  controller: _version,
                  suggestions: _distinct((kp) => kp.version),
                ),
                _field(
                  label: '册别（如 八年级上册）',
                  controller: _book,
                  suggestions: _distinct((kp) => kp.book),
                ),
                _field(
                  label: '章',
                  controller: _chapter,
                  suggestions: _distinct((kp) => kp.chapter),
                ),
                _field(
                  label: '节',
                  controller: _lesson,
                  suggestions: _distinct((kp) => kp.lesson),
                ),
                _field(
                  label: '知识点名称',
                  controller: _point,
                  suggestions: _distinct((kp) => kp.name),
                ),
              ],
            ),
          ),
          GrowthButton(
            label: '确定',
            expanded: true,
            onPressed: () => widget.onSave(
              KnowledgePath(
                subject: _subject.text.trim(),
                version: _version.text.trim(),
                book: _book.text.trim(),
                chapter: _chapter.text.trim(),
                lesson: _lesson.text.trim(),
                point: _point.text.trim(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
