import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/backup/backup_channel.dart';
import '../../../core/backup/webdav_client.dart';
import '../../../core/di/providers.dart';
import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// 备份设置页（Part 4）：三通道 WebDAV + local_export，
/// 测试连接通过才能保存；显示上次备份时间；立即备份/恢复。
class BackupSettingsPage extends ConsumerStatefulWidget {
  const BackupSettingsPage({super.key, this.focusRestore = false});

  /// 从首启引导「从云恢复」进入时置 true
  final bool focusRestore;

  @override
  ConsumerState<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends ConsumerState<BackupSettingsPage> {
  BackupChannelType _type = BackupChannelType.jianguoyun;
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _encrypt = false;
  bool _allowCellular = false;

  bool _testing = false;
  bool _testPassed = false;
  String? _testMessage;

  bool _backingUp = false;
  bool _restoring = false;
  DateTime? _lastBackupAt;
  String? _lastResultMsg;
  bool? _lastResultOk;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final state = ref.read(backupStateProvider);
    final config = state.loadConfig();
    if (config != null) {
      _type = config.type;
      _urlController.text = config.serverUrl;
      _usernameController.text = config.username;
      _encrypt = config.encryptEnabled;
      final password = await state.loadPassword();
      _passwordController.text = password;
    }
    _allowCellular = state.allowCellular;
    if (mounted) {
      setState(() {
        _lastBackupAt = state.lastBackupAt;
        _lastResultMsg = state.lastResultMessage;
        _lastResultOk = state.lastResultOk;
      });
    }
  }

  String get _effectiveUrl {
    switch (_type) {
      case BackupChannelType.jianguoyun:
        return BackupChannelConfig.jianguoyunUrl;
      case BackupChannelType.infinicloud:
        final custom = _urlController.text.trim();
        return custom.isNotEmpty
            ? custom
            : BackupChannelConfig.infinicloudUrl(
                _usernameController.text.trim());
      default:
        return _urlController.text.trim();
    }
  }

  bool _checkFields() {
    switch (_type) {
      case BackupChannelType.jianguoyun:
        return _usernameController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty;
      case BackupChannelType.infinicloud:
        return _usernameController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty;
      case BackupChannelType.customWebdav:
        return _urlController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty;
      case BackupChannelType.localExport:
        return true;
      default:
        return false;
    }
  }

  Future<void> _testConnection() async {
    if (_testing) return;
    if (_type == BackupChannelType.localExport) {
      setState(() {
        _testPassed = true;
        _testMessage = '本地导出不需要连接测试';
      });
      return;
    }
    if (!_checkFields()) {
      setState(() {
        _testPassed = false;
        _testMessage = '请先完整填写账号信息';
      });
      return;
    }
    setState(() {
      _testing = true;
      _testMessage = '正在测试连接…';
    });
    final client = WebDavClient(
      baseUrl: _effectiveUrl,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    final result = await client.testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testPassed = result.ok;
      _testMessage = result.message;
    });
  }

  Future<void> _save() async {
    // Part 4.4：测试连接通过后才能保存
    if (!_testPassed) {
      AppToast.error(context, '请先通过连接测试');
      return;
    }
    final config = BackupChannelConfig(
      type: _type,
      serverUrl: _type == BackupChannelType.jianguoyun
          ? BackupChannelConfig.jianguoyunUrl
          : _urlController.text.trim(),
      username: _usernameController.text.trim(),
      encryptEnabled: _encrypt,
    );
    await ref.read(backupStateProvider).saveConfig(
          config,
          password: _passwordController.text,
        );
    await ref.read(backupStateProvider).setAllowCellular(_allowCellular);
    if (mounted) {
      AppToast.success(context, '备份配置已保存');
      if (widget.focusRestore) {
        await _restore();
      }
    }
  }

  Future<void> _backupNow() async {
    if (_backingUp) return;
    setState(() => _backingUp = true);
    final result = await ref.read(backupServiceProvider).backupNow();
    if (!mounted) return;
    setState(() {
      _backingUp = false;
      _lastBackupAt = ref.read(backupStateProvider).lastBackupAt;
      _lastResultMsg = ref.read(backupStateProvider).lastResultMessage;
      _lastResultOk = ref.read(backupStateProvider).lastResultOk;
    });
    if (result.ok) {
      AppToast.success(context, result.message);
    } else {
      AppToast.error(context, result.message);
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    final confirm = await showGrowthDialog(
      context: context,
      title: '从云端恢复？',
      message: '恢复将覆盖当前全部数据与图片（取云端最新备份）。',
      confirmLabel: '恢复',
      destructive: true,
    );
    if (confirm != true) return;

    setState(() => _restoring = true);
    final result = await ref.read(backupServiceProvider).restoreLatest();
    if (!mounted) return;
    setState(() => _restoring = false);
    if (result.ok) {
      AppToast.success(context, result.message);
    } else {
      AppToast.error(context, result.message);
    }
    if (result.ok) {
      // 数据库实例已重建：作废依赖旧实例的所有 provider
      ref.invalidate(databaseProvider);
      if (mounted) context.go('/');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: growthAppBar(
        context,
        title: '云备份',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: GrowthBackground(
        child: ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            // ---- 通道选择 ----
            Text('备份通道', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: GrowthSpacing.sm),
            Wrap(
              spacing: GrowthSpacing.sm,
              runSpacing: GrowthSpacing.sm,
              children: [
                for (final (t, label) in [
                  (BackupChannelType.jianguoyun, '坚果云'),
                  (BackupChannelType.infinicloud, 'InfiniCLOUD'),
                  (BackupChannelType.customWebdav, '自定义 WebDAV'),
                  (BackupChannelType.localExport, '本地导出'),
                ])
                  GrowthChip(
                    label: label,
                    selected: _type == t,
                    onTap: () => setState(() {
                      _type = t;
                      _testPassed = false;
                      _testMessage = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: GrowthSpacing.md),

            // ---- 通道表单 ----
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_type == BackupChannelType.jianguoyun) ...[
                    Text(
                      '服务器地址：${BackupChannelConfig.jianguoyunUrl}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: GrowthSpacing.sm),
                    Text(
                      '使用坚果云「安全设置 → 第三方应用管理」创建的应用密码',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: _usernameController,
                      label: '坚果云账号（邮箱）',
                      hint: 'you@example.com',
                      onChanged: (_) => setState(() => _testPassed = false),
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: _passwordController,
                      label: '应用密码',
                      hint: '坚果云生成的应用密码',
                      obscure: true,
                      onChanged: (_) => setState(() => _testPassed = false),
                    ),
                  ],
                  if (_type == BackupChannelType.infinicloud) ...[
                    GrowthTextField(
                      controller: _usernameController,
                      label: 'InfiniCLOUD 用户名',
                      hint: '地址自动拼接为 {用户名}.teracloud.jp/dav/',
                      onChanged: (_) => setState(() => _testPassed = false),
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: _urlController,
                      label: '服务器地址（可选，默认自动拼接）',
                      hint: _usernameController.text.isEmpty
                          ? 'https://{用户名}.teracloud.jp/dav/'
                          : BackupChannelConfig.infinicloudUrl(
                              _usernameController.text.trim()),
                      onChanged: (_) => setState(() => _testPassed = false),
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: _passwordController,
                      label: '密码',
                      obscure: true,
                      onChanged: (_) => setState(() => _testPassed = false),
                    ),
                  ],
                  if (_type == BackupChannelType.customWebdav) ...[
                    GrowthTextField(
                      controller: _urlController,
                      label: 'WebDAV 地址（NAS/其他服务）',
                      hint: 'https://nas.example.com/dav/',
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() => _testPassed = false),
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: _usernameController,
                      label: '账号（可选）',
                      onChanged: (_) => setState(() => _testPassed = false),
                    ),
                    const SizedBox(height: GrowthSpacing.md),
                    GrowthTextField(
                      controller: _passwordController,
                      label: '密码',
                      obscure: true,
                      onChanged: (_) => setState(() => _testPassed = false),
                    ),
                  ],
                  if (_type == BackupChannelType.localExport)
                    Text(
                      '备份包导出到本机，可分享给任意 App（网盘/文件管理器）。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (_type != BackupChannelType.localExport) ...[
                    const SizedBox(height: GrowthSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AES 加密备份包',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text(
                                '使用上方密码加密，恢复时需同一密码',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _encrypt,
                          activeThumbColor: GrowthColors.primary,
                          onChanged: (v) => setState(() => _encrypt = v),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),

            // ---- 测试连接（保存前置条件） ----
            if (_testMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: GrowthSpacing.sm),
                child: Text(
                  _testMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _testPassed
                        ? GrowthColors.success
                        : GrowthColors.muted(
                            Theme.of(context).brightness == Brightness.light),
                  ),
                ),
              ),
            GrowthButton(
              label: '测试连接',
              variant: GrowthButtonVariant.secondary,
              expanded: true,
              loading: _testing,
              icon: _testPassed ? Icons.check_rounded : null,
              onPressed: _testConnection,
            ),
            const SizedBox(height: GrowthSpacing.sm),
            GrowthButton(
              label: '保存配置',
              expanded: true,
              onPressed: _testPassed ? _save : null,
            ),
            const SizedBox(height: GrowthSpacing.lg),

            // ---- 备份操作 ----
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GrowthSectionHeader(title: '备份操作'),
                  const SizedBox(height: GrowthSpacing.sm),
                  Text(
                    _lastBackupAt == null
                        ? '尚未备份'
                        : '上次备份：${DateFormat('yyyy-MM-dd HH:mm').format(_lastBackupAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_lastResultMsg != null) ...[
                    const SizedBox(height: GrowthSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          _lastResultOk == true
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          size: 14,
                          color: _lastResultOk == true
                              ? GrowthColors.success
                              : GrowthColors.error,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _lastResultMsg!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _lastResultOk == true
                                  ? GrowthColors.success
                                  : GrowthColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: GrowthSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GrowthButton(
                          label: '立即备份',
                          loading: _backingUp,
                          onPressed: _backupNow,
                        ),
                      ),
                      const SizedBox(width: GrowthSpacing.sm),
                      Expanded(
                        child: GrowthButton(
                          label: '从云恢复',
                          variant: GrowthButtonVariant.secondary,
                          loading: _restoring,
                          onPressed: _restore,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('允许移动网络自动备份',
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                              '关闭时仅 WiFi 下自动备份',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _allowCellular,
                        activeThumbColor: GrowthColors.primary,
                        onChanged: (v) async {
                          setState(() => _allowCellular = v);
                          await ref
                              .read(backupStateProvider)
                              .setAllowCellular(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: GrowthSpacing.xs),
                  Text(
                    '自动备份：数据有变更且退到后台时触发；云端保留最近 3 个版本，恢复取最新。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.xl),
          ],
        ),
      ),
    );
  }
}
