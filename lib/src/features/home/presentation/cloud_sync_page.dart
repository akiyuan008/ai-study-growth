import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// 云同步页（单用户模式）：安装即自动同步，本页只看状态与手动触发
class CloudSyncPage extends ConsumerStatefulWidget {
  const CloudSyncPage({super.key});

  @override
  ConsumerState<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends ConsumerState<CloudSyncPage> {
  bool _busy = false;
  String? _lastSyncDisplay;
  bool _online = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final ts = prefs.getString('cloud.last_sync_at');
    final sync = ref.read(cloudSyncProvider);
    final online = await sync.ensureSignedIn();
    if (!mounted) return;
    setState(() {
      _lastSyncDisplay = ts;
      _online = online;
    });
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
      setState(() {
        _lastSyncDisplay = stamp;
        _online = true;
      });
      AppToast.success(context, result.message);
    } else {
      AppToast.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    _online
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: _online ? GrowthColors.success : GrowthColors.gray4,
                    size: 28,
                  ),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _online ? '云同步正常' : '云同步暂不可用',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: GrowthSpacing.xs),
                        Text(
                          _online
                              ? (_lastSyncDisplay != null
                                  ? '上次同步：$_lastSyncDisplay'
                                  : '数据实时守护中')
                              : '检查网络后会自动恢复，本地数据不受影响',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.lg),

            GrowthButton(
              label: _busy ? '正在同步…' : '立即同步',
              icon: Icons.sync_rounded,
              expanded: true,
              onPressed: _busy ? null : _sync,
            ),
            const SizedBox(height: GrowthSpacing.md),
            _ExplainCard(items: const [
              '安装即用：错题、知识点、复习进度、举一反三、题目图片自动同步到云端',
              '拍题保存、复习评分后联网时自动补同步，回到前台也会补同步',
              '删除的题目会从云端一并清除，两端数据保持一致',
              '换机或重装：登录同一账号的数据自动拉回',
              'AI 密钥等敏感配置不参与云同步，仅保存在本机',
            ]),
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
