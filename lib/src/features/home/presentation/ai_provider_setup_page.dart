import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/ai_config_repository.dart';
import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// AI 服务商配置页（Prompt G 修复版）：
/// - hydrate 回填（Key 掩码）
/// - 获取模型只校验 URL+Key，成功弹选择 BottomSheet
/// - URL 自动补全 https://、测试连接有明确反馈、灰色 helper 校验
class AiProviderSetupPage extends ConsumerStatefulWidget {
  const AiProviderSetupPage({super.key});

  @override
  ConsumerState<AiProviderSetupPage> createState() =>
      _AiProviderSetupPageState();
}

class _AiProviderSetupPageState extends ConsumerState<AiProviderSetupPage> {
  final _nameController = TextEditingController(text: '主力模型');
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();

  bool _hydrated = false;
  bool _fetchingModels = false;
  bool _testing = false;
  bool _saving = false;

  /// Part 0.4：测试连接通过才能保存
  bool _testPassed = false;

  /// 校验提示（灰色 helper，指明缺哪一项）
  String? _helper;

  AiConfigRepository get _configRepo => ref.read(aiConfigRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  /// G1：初始化从仓库 hydrate 回填
  Future<void> _hydrate() async {
    final draft = await _configRepo.loadDraft();
    if (!mounted) return;
    final config = draft.config;
    if (config != null) {
      _nameController.text = config.name;
      _baseUrlController.text = config.baseUrl;
      _modelController.text = config.model;
      _apiKeyController.text = draft.apiKey;
    }
    setState(() => _hydrated = true);
  }

  void _markDirty() {
    if (_testPassed) setState(() => _testPassed = false);
  }

  bool _checkRequired({bool needModel = true}) {
    final missing = <String>[];
    if (_baseUrlController.text.trim().isEmpty) missing.add('Base URL');
    if (_apiKeyController.text.trim().isEmpty) missing.add('API Key');
    if (needModel && _modelController.text.trim().isEmpty) {
      missing.add('模型');
    }
    if (missing.isEmpty) {
      setState(() => _helper = null);
      return true;
    }
    setState(() => _helper = '还差：${missing.join('、')}');
    return false;
  }

  /// G2：获取模型——只校验 Base URL + API Key，解除死锁
  Future<void> _fetchModels() async {
    if (_fetchingModels) return;
    if (!_checkRequired(needModel: false)) return;

    setState(() {
      _fetchingModels = true;
      _helper = null;
    });
    final result = await _configRepo.fetchModels(
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
    );
    if (!mounted) return;
    setState(() => _fetchingModels = false);

    if (result.error != null) {
      AppToast.error(context, result.error!);
      return;
    }
    if (result.models.isEmpty) {
      AppToast.info(context, '未获取到模型，可手动填写模型名');
      return;
    }
    _openModelSheet(result.models);
  }

  /// 模型选择 BottomSheet（Part 1.5）：
  /// 搜索 + 智能排序（对话/多模态优先，image/edit/embedding/tts 沉底）
  /// + 「视觉」标签 + 行高≤52px + 过滤后计数
  void _openModelSheet(List<String> models) {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => _ModelPickerSheet(
        models: models,
        current: _modelController.text.trim(),
        onPick: (m) {
          _modelController.text = m;
          setState(() => _testPassed = false);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_testing) return;
    if (!_checkRequired()) return;

    setState(() {
      _testing = true;
      _helper = null;
    });
    final result = await _configRepo.testConnection(
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      if (result.ok) _testPassed = true;
    });
    AppToast.show(context, result.message,
        kind: result.ok ? ToastKind.success : ToastKind.error);
  }

  /// G5：保存成功 toast 并返回（前置：测试连接通过）
  Future<void> _save() async {
    if (_saving) return;
    if (!_checkRequired()) return;
    if (!_testPassed) {
      AppToast.error(context, '请先通过连接测试，再保存配置');
      return;
    }

    setState(() {
      _saving = true;
      _helper = null;
    });
    try {
      await _configRepo.save(
        name: _nameController.text,
        baseUrl: _baseUrlController.text,
        model: _modelController.text,
        apiKey: _apiKeyController.text,
      );
      ref.invalidate(defaultAiConfigProvider);
      ref.invalidate(aiGatewayProvider);
      if (mounted) {
        AppToast.success(context, 'AI 服务商已保存并设为默认');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static const _presets = {
    'OpenAI': 'https://api.openai.com/v1',
    'DeepSeek': 'https://api.deepseek.com/v1',
    'Moonshot': 'https://api.moonshot.cn/v1',
    '智谱': 'https://open.bigmodel.cn/api/paas/v4',
    '通义千问': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: growthAppBar(
        context,
        title: 'AI 服务商',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: GrowthBackground(
        child: ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('预设', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: GrowthSpacing.sm),
                  Wrap(
                    spacing: GrowthSpacing.sm,
                    runSpacing: GrowthSpacing.sm,
                    children: [
                      for (final e in _presets.entries)
                        GrowthChip(
                          label: e.key,
                          selected: _baseUrlController.text.trim() == e.value,
                          onTap: () =>
                              setState(() => _baseUrlController.text = e.value),
                        ),
                    ],
                  ),
                  const SizedBox(height: GrowthSpacing.lg),
                  GrowthTextField(
                    controller: _nameController,
                    onChanged: (_) => _markDirty(),
                    label: '名称',
                    hint: '主力模型',
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthTextField(
                    controller: _baseUrlController,
                    onChanged: (_) => _markDirty(),
                    label: 'Base URL（OpenAI 兼容）',
                    hint: 'api.example.com/v1（自动补 https://）',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthTextField(
                    controller: _apiKeyController,
                    onChanged: (_) => _markDirty(),
                    label: 'API Key（加密存储，不落数据库）',
                    hint: 'sk-...',
                    obscure: true,
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthTextField(
                    controller: _modelController,
                    onChanged: (_) => _markDirty(),
                    label: '模型',
                    hint: '点「获取模型」选择，或手动填写',
                  ),
                  if (_helper != null) ...[
                    const SizedBox(height: GrowthSpacing.sm),
                    Text(
                      _helper!,
                      style: TextStyle(
                        fontSize: 13,
                        color: GrowthColors.muted(
                            Theme.of(context).brightness == Brightness.light),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: GrowthButton(
                    label: '获取模型',
                    variant: GrowthButtonVariant.secondary,
                    loading: _fetchingModels,
                    onPressed: _fetchModels,
                  ),
                ),
                const SizedBox(width: GrowthSpacing.sm),
                Expanded(
                  child: GrowthButton(
                    label: '测试连接',
                    variant: GrowthButtonVariant.secondary,
                    loading: _testing,
                    onPressed: _testConnection,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GrowthSpacing.md),
            GrowthButton(
              label: '保存并设为默认',
              icon: Icons.check_rounded,
              expanded: true,
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: GrowthSpacing.md),
            Text(
              '说明：知识点识别、AI 追问、举一反三共用这一套配置。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: GrowthSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// 模型选择器：搜索 + 智能排序 + 视觉标签
class _ModelPickerSheet extends StatefulWidget {
  const _ModelPickerSheet({
    required this.models,
    required this.current,
    required this.onPick,
  });

  final List<String> models;
  final String current;
  final ValueChanged<String> onPick;

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  String _query = '';

  /// 非对话类模型关键词（沉底）
  static const _sinkKeywords = [
    'image',
    'edit',
    'embed',
    'tts',
    'whisper',
    'speech',
    'moderation',
    'rerank',
    'audio',
    'video',
  ];

  /// 视觉能力关键词（打「视觉」标签）
  static const _visionKeywords = [
    'vision',
    'vl',
    'gpt-4o',
    'gpt-4-turbo',
    'omni'
  ];

  bool _isSink(String m) {
    final lower = m.toLowerCase();
    return _sinkKeywords.any(lower.contains);
  }

  bool _isVision(String m) {
    final lower = m.toLowerCase();
    return _visionKeywords.any(lower.contains);
  }

  int _rank(String m) {
    if (_isSink(m)) return 2; // 沉底
    if (_isVision(m)) return 0; // 多模态优先
    return 1; // 普通对话模型
  }

  List<String> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.models
        : widget.models.where((m) => m.toLowerCase().contains(q)).toList();
    return [...list]..sort((a, b) {
        final ra = _rank(a);
        final rb = _rank(b);
        if (ra != rb) return ra.compareTo(rb);
        return a.compareTo(b);
      });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('选择模型（${filtered.length} 个）',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (widget.models.length > 8)
                SizedBox(
                  width: 160,
                  child: GrowthTextField(
                    hint: '搜索',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
            ],
          ),
          const SizedBox(height: GrowthSpacing.sm),
          Text('多模态（视觉）优先，图像/语音等专用模型沉底',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: GrowthSpacing.sm),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    title: '没有匹配的模型',
                    subtitle: _query.isEmpty ? null : '换个关键词试试',
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final m = filtered[i];
                      final vision = _isVision(m);
                      return InkWell(
                        onTap: () => widget.onPick(m),
                        borderRadius: BorderRadius.circular(GrowthRadii.icon),
                        child: Container(
                          height: 52, // 行高≤52px
                          padding: const EdgeInsets.symmetric(
                              horizontal: GrowthSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: m == widget.current
                                            ? FontWeight.w700
                                            : null,
                                      ),
                                ),
                              ),
                              if (vision) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: GrowthColors.learning
                                        .withValues(alpha: 0.14),
                                    borderRadius:
                                        BorderRadius.circular(GrowthRadii.icon),
                                  ),
                                  child: const Text(
                                    '视觉',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: GrowthColors.learning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (m == widget.current)
                                const Icon(Icons.check_rounded,
                                    size: 18, color: GrowthColors.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
