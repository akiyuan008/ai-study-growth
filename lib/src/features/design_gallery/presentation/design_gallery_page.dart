
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';

/// 设计系统画廊 —— P1 验收页：全部组件与令牌的可视化清单。
class DesignGalleryPage extends ConsumerStatefulWidget {
  const DesignGalleryPage({super.key});

  @override
  ConsumerState<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends ConsumerState<DesignGalleryPage> {
  bool _chipSelected = true;
  bool _buttonLoading = false;

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: growthAppBar(
        context,
        title: '设计系统画廊',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GrowthSpacing.lg),
        children: [
          _section('主题管理'),
          GlassCard(
            child: Text(
              '本版固定浅色（深色模式 P5 解锁），主题切换控件已冻结。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _section('色彩令牌'),
          GrowthCard(
            child: Wrap(
              spacing: GrowthSpacing.md,
              runSpacing: GrowthSpacing.md,
              children: [
                _swatch('种子', GrowthColors.primary),
                _swatch('生长', GrowthColors.success),
                _swatch('行动强调', GrowthColors.actionAccent),
                _swatch('警示', GrowthColors.caution),
                _swatch('学习', GrowthColors.abilityLearning),
                _swatch('专注', GrowthColors.abilityFocus),
                _swatch('坚持', GrowthColors.abilityPersistence),
                _swatch('恢复', GrowthColors.abilityRecovery),
              ],
            ),
          ),
          _section('字体规范'),
          GrowthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('headline 28/w700',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: GrowthSpacing.sm),
                Text('title 20/w600',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: GrowthSpacing.sm),
                Text('body 15/w400 —— 大量留白，注意力聚焦当前任务',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: GrowthSpacing.sm),
                Text('caption 13 —— 辅助说明',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          _section('按钮'),
          GrowthCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GrowthButton(
                        label: '主要',
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: GrowthSpacing.sm),
                    Expanded(
                      child: GrowthButton(
                        label: '玻璃',
                        variant: GrowthButtonVariant.secondary,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GrowthSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GrowthButton(
                        label: '幽灵',
                        variant: GrowthButtonVariant.ghost,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: GrowthSpacing.sm),
                    Expanded(
                      child: GrowthButton(
                        label: '危险',
                        variant: GrowthButtonVariant.danger,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GrowthSpacing.md),
                GrowthButton(
                  label: _buttonLoading ? '解析中' : '加载态演示',
                  loading: _buttonLoading,
                  expanded: true,
                  onPressed: () async {
                    setState(() => _buttonLoading = true);
                    await Future<void>.delayed(const Duration(seconds: 2));
                    if (mounted) setState(() => _buttonLoading = false);
                  },
                ),
              ],
            ),
          ),
          _section('标签 Chip'),
          GrowthCard(
            child: Wrap(
              spacing: GrowthSpacing.sm,
              runSpacing: GrowthSpacing.sm,
              children: [
                GrowthChip(
                  label: '压强',
                  selected: _chipSelected,
                  onTap: () => setState(() => _chipSelected = !_chipSelected),
                ),
                const GrowthChip(label: '力学', color: GrowthColors.abilityFocus),
                const GrowthChip(
                    label: '自由落体', color: GrowthColors.abilityPersistence),
                const GrowthChip(label: '待巩固', color: GrowthColors.caution),
              ],
            ),
          ),
          _section('输入框'),
          GrowthCard(
            child: GrowthTextField(
              label: '给 AI 助教留言',
              hint: '例如：今天想先复习物理错题…',
            ),
          ),
          const SizedBox(height: GrowthSpacing.xl),
        ],
      ),
    ));
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: GrowthSpacing.lg,
        bottom: GrowthSpacing.sm,
      ),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _swatch(String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: GrowthSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
