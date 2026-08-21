import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// 云同步页（Supabase）：一键开启 / 手动同步 / 状态可见
class CloudSyncPage extends ConsumerStatefulWidget {
  const CloudSyncPage({super.key});

  @override
  ConsumerState<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends ConsumerState<CloudSyncPage> {
  bool _busy = false;
  String? _lastSyncDisplay;

  @override
  void initState() {
    super.initState();
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final ts = prefs.getString('cloud.last_sync_at');
    if (ts != null && mounted) {
      setState(() => _lastSyncDisplay = ts);
    }
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    final result = await ref.read(cloudSyncProvider).signInAnonymously();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.ok) {
      AppToast.success(context, result.message);
      // 开启后立即同步一次
      await _sync();
    } else {
      AppToast.error(context, result.message);
    }
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    final result = await ref.read(cloudSyncProvider).syncNow();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.ok) {
      final stamp = DateFormat('MM-dd HH:mm').format(DateTime.now());
      await ref
          .read(sharedPreferencesProvider)
          .setString('cloud.last_sync_at', stamp);
      if (!mounted) return;
      setState(() => _lastSyncDisplay = stamp);
      AppToast.success(context, result.message);
    } else {
      AppToast.error(context, result.message);
    }
  }

  Future<void> _signOut() async {
    final ok = await showGrowthDialog(
      context: context,
      title: '关闭云同步？',
      message: '关闭后不再上传新数据。本地数据不受影响，云端已备份的数据保留。',
      confirmLabel: '关闭',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    await ref.read(cloudSyncProvider).signOut();
    if (mounted) {
      setState(() {});
      AppToast.info(context, '已关闭云同步');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(cloudSyncProvider);
    final signedIn = sync.isSignedIn;

    return Scaffold(
      appBar: growthAppBar(context, title: '云同步', showBack: true),
      body: GrowthBackground(
        child: ListView(
          padding: const EdgeInsets.all(GrowthSpacing.lg),
          children: [
            // 状态卡
            GlassCard(
              child: Row(
                children: [
                  Icon(
                    signedIn
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: signedIn ? GrowthColors.success : GrowthColors.gray4,
                    size: 28,
                  ),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signedIn ? '云同步已开启' : '云同步未开启',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: GrowthSpacing.xs),
                        Text(
                          signedIn
                              ? (_lastSyncDisplay != null
                                  ? '上次同步：$_lastSyncDisplay'
                                  : '数据将加密隔离存储在你的专属空间')
                              : '错题、复习进度与图片将同步到云端，换机可恢复',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.lg),

            if (!signedIn) ...[
              GrowthButton(
                label: _busy ? '正在开启…' : '一键开启云同步',
                icon: Icons.cloud_upload_rounded,
                expanded: true,
                onPressed: _busy ? null : _enable,
              ),
              const SizedBox(height: GrowthSpacing.md),
              _ExplainCard(items: const [
                '免注册：本设备获得专属匿名身份，数据仅你可见',
                '同步内容：错题、知识点、复习进度、举一反三、题目图片',
                'AI 密钥等敏感配置不参与云同步，仅保存在本机',
                '离线时全功能照常使用，联网后可手动或自动补同步',
              ]),
            ] else ...[
              GrowthButton(
                label: _busy ? '正在同步…' : '立即同步',
                icon: Icons.sync_rounded,
                expanded: true,
                onPressed: _busy ? null : _sync,
              ),
              const SizedBox(height: GrowthSpacing.md),
              GrowthButton(
                label: '关闭云同步',
                icon: Icons.cloud_off_rounded,
                variant: GrowthButtonVariant.secondary,
                expanded: true,
                onPressed: _busy ? null : _signOut,
              ),
              const SizedBox(height: GrowthSpacing.md),
              _ExplainCard(items: const [
                '拍题保存、复习评分后联网时会自动补同步',
                '也可随时点「立即同步」手动触发',
              ]),
            ],
            const SizedBox(height: GrowthSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  const _ExplainCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const SizedBox(height: GrowthSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: GrowthColors.success),
                const SizedBox(width: GrowthSpacing.sm),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
