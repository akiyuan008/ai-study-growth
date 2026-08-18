import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// App 分类管理：监控白名单（这些应用的前台切换不算分心）
class AppWhitelistPage extends ConsumerStatefulWidget {
  const AppWhitelistPage({super.key});

  @override
  ConsumerState<AppWhitelistPage> createState() => _AppWhitelistPageState();
}

class _AppWhitelistPageState extends ConsumerState<AppWhitelistPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final pkg = _controller.text.trim();
    if (pkg.isEmpty) return;
    await ref.read(settingsServiceProvider).addWhitelist(pkg);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsServiceProvider);
    final whitelist = settings.whitelist;

    return Scaffold(
      appBar: growthAppBar(
        context,
        title: 'App 分类管理',
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
                  Text(
                    '白名单应用',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: GrowthSpacing.xs),
                  Text(
                    '专注期间切到白名单应用不算分心（如词典、计算器）。系统桌面与系统 UI 默认豁免。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: GrowthSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GrowthTextField(
                          controller: _controller,
                          hint: '包名，如 com.example.dict',
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: GrowthSpacing.sm),
                      GrowthButton(label: '添加', onPressed: _add),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowthSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GrowthSectionHeader(title: '当前白名单'),
                  const SizedBox(height: GrowthSpacing.sm),
                  if (whitelist.isEmpty)
                    Text(
                      '还没有添加任何应用',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  for (final pkg in whitelist)
                    Padding(
                      padding: const EdgeInsets.only(bottom: GrowthSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: GrowthColors.success),
                          const SizedBox(width: GrowthSpacing.sm),
                          Expanded(
                            child: Text(
                              pkg,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: GrowthColors.warning),
                            onPressed: () async {
                              await ref
                                  .read(settingsServiceProvider)
                                  .removeWhitelist(pkg);
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
