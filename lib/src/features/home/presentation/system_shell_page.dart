import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../design_system/design_system.dart';

/// P0 系统壳首页：验证基座可用性（数据库、Drift schema、Riverpod）。
/// P4 起由真正的 Growth Home 替换。
class SystemShellPage extends ConsumerStatefulWidget {
  const SystemShellPage({super.key});

  @override
  ConsumerState<SystemShellPage> createState() => _SystemShellPageState();
}

class _SystemShellPageState extends ConsumerState<SystemShellPage> {
  String _dbStatus = '检测中…';

  @override
  void initState() {
    super.initState();
    _probeDatabase();
  }

  Future<void> _probeDatabase() async {
    final db = ref.read(databaseProvider);
    try {
      // 对每张核心表执行一次空查询，验证 schema 全部生效
      await (db.select(db.questionRecords)..limit(1)).get();
      await (db.select(db.knowledgePoints)..limit(1)).get();
      await (db.select(db.reviewCards)..limit(1)).get();
      await (db.select(db.reviewLogs)..limit(1)).get();
      await (db.select(db.generatedExercises)..limit(1)).get();
      await (db.select(db.aiMessages)..limit(1)).get();
      await (db.select(db.focusSessions)..limit(1)).get();
      await (db.select(db.focusEvents)..limit(1)).get();
      await (db.select(db.missions)..limit(1)).get();
      await (db.select(db.learningEvents)..limit(1)).get();
      await (db.select(db.growthMetrics)..limit(1)).get();
      await (db.select(db.aiProviders)..limit(1)).get();
      if (mounted) setState(() => _dbStatus = '13 张核心表全部就绪');
    } catch (e) {
      if (mounted) setState(() => _dbStatus = '异常：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GrowthSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI 学习成长系统',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: GrowthSpacing.sm),
                Text(
                  '自律学习 × AI 错题本 · 基座验证',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: GrowthSpacing.xl),
                GrowthCard(
                  child: Column(
                    children: [
                      _statusRow('数据库 (Drift)', _dbStatus),
                      const SizedBox(height: GrowthSpacing.md),
                      _statusRow('AI Provider', '模块已装载 · 待配置'),
                      const SizedBox(height: GrowthSpacing.md),
                      _statusRow('设计系统', 'P1 组件库已就绪'),
                      const SizedBox(height: GrowthSpacing.md),
                      _statusRow('Kotlin 桥接层', 'P3 接入'),
                    ],
                  ),
                ),
                const SizedBox(height: GrowthSpacing.lg),
                GrowthButton(
                  label: '设计系统画廊',
                  icon: Icons.palette_outlined,
                  expanded: true,
                  onPressed: () => context.push('/design/gallery'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: GrowthColors.seed,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
