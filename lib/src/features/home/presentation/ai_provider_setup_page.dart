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

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      _toast(result.error!);
      return;
    }
    if (result.models.isEmpty) {
      _toast('未获取到模型，可手动填写模型名');
      return;
    }
    _openModelSheet(result.models);
  }

  /// 模型选择 BottomSheet：选中回填，仍可手动输入
  void _openModelSheet(List<String> models) {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择模型', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: GrowthSpacing.sm),
            Text('共 ${models.length} 个可用模型，点选回填，也可关闭后手动输入',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: GrowthSpacing.md),
            Expanded(
              child: ListView.builder(
                itemCount: models.length,
                itemBuilder: (context, i) {
                  final m = models[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title:
                        Text(m, style: Theme.of(context).textTheme.bodyMedium),
                    trailing: _modelController.text == m
                        ? const Icon(Icons.check_rounded,
                            color: GrowthColors.primary, size: 18)
                        : null,
                    onTap: () {
                      _modelController.text = m;
                      Navigator.of(sheetContext).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// G4：测试连接——loading + 明确成功/失败反馈
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
    setState(() => _testing = false);
    _toast(result.message);
  }

  /// G5：保存成功 toast 并返回
  Future<void> _save() async {
    if (_saving) return;
    if (!_checkRequired()) return;

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
        _toast('AI 服务商已保存并设为默认');
        context.pop();
      }
    } catch (e) {
      _toast('保存失败：$e');
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
                    label: '名称',
                    hint: '主力模型',
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthTextField(
                    controller: _baseUrlController,
                    label: 'Base URL（OpenAI 兼容）',
                    hint: 'api.example.com/v1（自动补 https://）',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthTextField(
                    controller: _apiKeyController,
                    label: 'API Key（加密存储，不落数据库）',
                    hint: 'sk-...',
                    obscure: true,
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  GrowthTextField(
                    controller: _modelController,
                    label: '模型',
                    hint: '点「获取模型」选择，或手动填写',
                  ),
                  if (_helper != null) ...[
                    const SizedBox(height: GrowthSpacing.sm),
                    Text(
                      _helper!,
                      style: TextStyle(
                        fontSize: 13,
                        color: GrowthColors.gray5,
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
              '说明：拍题解析、AI 追问、举一反三、MOSS 伴读共用这一套配置。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: GrowthSpacing.xl),
          ],
        ),
      ),
    );
  }
}
