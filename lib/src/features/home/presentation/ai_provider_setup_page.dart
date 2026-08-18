import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_client.dart';
import '../../../core/ai/ai_provider_config.dart';
import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// AI 服务商配置页：填写 → 拉模型列表 → 测试连接 → 保存
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

  bool _busy = false;
  String? _status;
  List<String> _models = const [];

  static const _presets = {
    'OpenAI': 'https://api.openai.com/v1',
    'DeepSeek': 'https://api.deepseek.com/v1',
    'Moonshot': 'https://api.moonshot.cn/v1',
    '智谱': 'https://open.bigmodel.cn/api/paas/v4',
    '通义千问': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
  };

  AiProviderConfig? _draft() {
    if (_baseUrlController.text.trim().isEmpty ||
        _modelController.text.trim().isEmpty) {
      return null;
    }
    return AiProviderConfig.create(
      name: _nameController.text.trim().isEmpty
          ? '主力模型'
          : _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      isDefault: true,
    );
  }

  AiClient _tempClient(AiProviderConfig config) =>
      AiClient(config: config, apiKey: _apiKeyController.text.trim());

  Future<void> _fetchModels() async {
    final config = _draft();
    if (config == null || _apiKeyController.text.trim().isEmpty) {
      setState(() => _status = '请先填写 Base URL 和 API Key');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在获取模型列表…';
    });
    try {
      final models = await _tempClient(config).fetchModels();
      setState(() {
        _models = models;
        _status = models.isEmpty ? '未获取到模型，可手动填写' : '获取到 ${models.length} 个模型';
      });
    } catch (e) {
      setState(() => _status = '获取失败：请检查 Base URL 与密钥');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testConnection() async {
    final config = _draft();
    if (config == null || _apiKeyController.text.trim().isEmpty) {
      setState(() => _status = '请先完整填写配置');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在测试连接…';
    });
    try {
      final ok = await _tempClient(config).testConnection();
      setState(() => _status = ok ? '连接成功 ✓' : '连接失败：请检查配置');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final config = _draft();
    if (config == null || _apiKeyController.text.trim().isEmpty) {
      setState(() => _status = '请先完整填写配置');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(aiProviderRepositoryProvider).save(
            config: config,
            apiKey: _apiKeyController.text.trim(),
          );
      ref.invalidate(defaultAiConfigProvider);
      ref.invalidate(aiGatewayProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 服务商已保存并设为默认')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('AI 服务商')),
      body: ListView(
        padding: const EdgeInsets.all(GrowthSpacing.lg),
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
            hint: 'https://api.example.com/v1',
          ),
          const SizedBox(height: GrowthSpacing.md),
          GrowthTextField(
            controller: _apiKeyController,
            label: 'API Key（加密存储，不落数据库）',
            hint: 'sk-...',
          ),
          const SizedBox(height: GrowthSpacing.md),
          GrowthTextField(
            controller: _modelController,
            label: '模型',
            hint: '从下方获取或手动填写',
          ),
          if (_models.isNotEmpty) ...[
            const SizedBox(height: GrowthSpacing.sm),
            Wrap(
              spacing: GrowthSpacing.sm,
              runSpacing: GrowthSpacing.sm,
              children: [
                for (final m in _models.take(12))
                  GrowthChip(
                    label: m,
                    selected: _modelController.text == m,
                    onTap: () => setState(() => _modelController.text = m),
                  ),
              ],
            ),
          ],
          const SizedBox(height: GrowthSpacing.lg),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: GrowthSpacing.md),
              child: Text(
                _status!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GrowthColors.primary,
                    ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: GrowthButton(
                  label: '获取模型',
                  variant: GrowthButtonVariant.secondary,
                  loading: _busy,
                  onPressed: _fetchModels,
                ),
              ),
              const SizedBox(width: GrowthSpacing.sm),
              Expanded(
                child: GrowthButton(
                  label: '测试连接',
                  variant: GrowthButtonVariant.secondary,
                  loading: _busy,
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
            loading: _busy,
            onPressed: _save,
          ),
          const SizedBox(height: GrowthSpacing.md),
          Text(
            '说明：拍题解析、AI 追问、举一反三、MOSS 伴读共用这一套配置。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
