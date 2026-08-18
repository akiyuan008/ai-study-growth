import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import 'focus_active_page.dart';

/// 专注结算页：真实专注时长、分心次数、成长反馈
class FocusResultPage extends ConsumerWidget {
  const FocusResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(focusOutcomeProvider);
    if (outcome == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('专注结果')),
        body: const GrowthEmptyState(message: '没有会话记录'),
      );
    }

    final focusMin = (outcome.focusMs / 60000).floor();
    final totalMin = (outcome.totalMs / 60000).floor();
    final ratio = outcome.focusRatio;
    final message = switch (ratio) {
      >= 0.9 => '近乎完美的专注，这就是心流的样子。',
      >= 0.7 => '很扎实的一次专注，继续保持。',
      >= 0.5 => '有过分心，但你回来了——这本身就是成长。',
      _ => '这次有点难，没关系，下一次会更稳。',
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF171B26), Color(0xFF0E1118)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(GrowthSpacing.xl),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  '专注结束',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: GrowthSpacing.lg),
                Text(
                  '$focusMin',
                  style: GrowthType.display.copyWith(
                    color: GrowthColors.flow,
                    fontSize: 96,
                  ),
                ),
                Text(
                  '分钟真实专注',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: GrowthSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stat('总时长', '$totalMin 分钟'),
                    const SizedBox(width: GrowthSpacing.xl),
                    _stat('专注率', '${(ratio * 100).round()}%'),
                    const SizedBox(width: GrowthSpacing.xl),
                    _stat('分心', '${outcome.distractionCount} 次'),
                  ],
                ),
                const SizedBox(height: GrowthSpacing.xl),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const Spacer(),
                GrowthButton(
                  label: '回到首页',
                  expanded: true,
                  onPressed: () => context.go('/'),
                ),
                const SizedBox(height: GrowthSpacing.sm),
                GrowthButton(
                  label: '再来一次',
                  variant: GrowthButtonVariant.secondary,
                  expanded: true,
                  onPressed: () => context.go('/focus'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: GrowthSpacing.xs),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
