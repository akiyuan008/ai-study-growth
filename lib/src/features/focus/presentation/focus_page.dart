import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../focus/focus_providers.dart';
import '../../learning/learning_providers.dart';

/// 专注启动页：选模式、选时长、可选关联题目
class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key, this.questionId, this.initialMode});

  final String? questionId;

  /// 路由预选模式（focus?mode=abyss）
  final FocusMode? initialMode;

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  late FocusMode _mode = widget.initialMode ??
      (ref.read(settingsServiceProvider).abyssDefault
          ? FocusMode.abyss
          : FocusMode.normal);
  int _minutes = 25;
  bool _starting = false;

  static const _presets = [15, 25, 45, 60];

  Future<void> _start() async {
    if (_starting) return;

    final bridge = ref.read(monitorBridgeProvider);
    final granted = await bridge.isUsageAccessGranted();
    if (!mounted) return;
    if (!granted) {
      final goSettings = await showGrowthDialog(
        context: context,
        title: '需要使用统计权限',
        message: '专注监控需要「使用情况访问」权限，用来感知你是否切出了 App。没有它，MOSS 无法在你分心时提醒你。',
        confirmLabel: '去授权',
      );
      if (goSettings == true) {
        await bridge.openUsageAccessSettings();
      }
      return;
    }

    await bridge.requestNotificationPermission();

    setState(() => _starting = true);
    try {
      await ref.read(activeFocusProvider.notifier).start(
            FocusStartRequest(
              mode: _mode,
              planned: Duration(minutes: _minutes),
              questionIds:
                  widget.questionId != null ? [widget.questionId!] : const [],
            ),
          );
      if (mounted) {
        context.pushReplacement('/focus/active');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkedQuestionAsync = widget.questionId == null
        ? null
        : ref.watch(_linkedQuestionProvider(widget.questionId!));

    return GrowthBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('开始专注')),
      body: ListView(
        padding: const EdgeInsets.all(GrowthSpacing.lg),
        children: [
          if (linkedQuestionAsync != null)
            linkedQuestionAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (q) => q == null
                  ? const SizedBox.shrink()
                  : GrowthCard(
                      margin: const EdgeInsets.only(bottom: GrowthSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded,
                              color: GrowthColors.abilityFocus),
                          const SizedBox(width: GrowthSpacing.sm),
                          Expanded(
                            child: Text(
                              '本次专注攻克：${q.stem}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          Text('模式', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: GrowthSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: '普通',
                  desc: '分心 1 分钟提醒\n5 分钟锁屏',
                  selected: _mode == FocusMode.normal,
                  onTap: () => setState(() => _mode = FocusMode.normal),
                ),
              ),
              const SizedBox(width: GrowthSpacing.md),
              Expanded(
                child: _ModeCard(
                  title: '深渊',
                  desc: '分心 30 秒提醒\n2 分钟锁屏',
                  selected: _mode == FocusMode.abyss,
                  onTap: () => setState(() => _mode = FocusMode.abyss),
                ),
              ),
            ],
          ),
          const SizedBox(height: GrowthSpacing.lg),
          Text('时长', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: GrowthSpacing.sm),
          Wrap(
            spacing: GrowthSpacing.sm,
            runSpacing: GrowthSpacing.sm,
            children: [
              for (final m in _presets)
                GrowthChip(
                  label: '$m 分钟',
                  selected: _minutes == m,
                  onTap: () => setState(() => _minutes = m),
                ),
            ],
          ),
          const SizedBox(height: GrowthSpacing.xl),
          GrowthButton(
            label: _starting ? '正在启动' : '进入专注',
            icon: Icons.center_focus_strong_rounded,
            expanded: true,
            loading: _starting,
            onPressed: _start,
          ),
          const SizedBox(height: GrowthSpacing.md),
          Text(
            '提示：专注期间切出 App 会被 MOSS 记录；真实专注时长只算你留在任务上的时间。',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ));
  }
}

final _linkedQuestionProvider =
    FutureProvider.autoDispose.family<QuestionRecord?, String>((ref, id) async {
  return ref.watch(questionRepositoryProvider).get(id);
});

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GrowthRadii.card),
        child: AnimatedContainer(
          duration: GrowthMotion.fast,
          padding: const EdgeInsets.all(GrowthSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? GrowthColors.primary.withValues(alpha: 0.12)
                : GrowthColors.glassLight,
            borderRadius: BorderRadius.circular(GrowthRadii.card),
            border: Border.all(
              color: selected
                  ? GrowthColors.primary
                  : GrowthColors.glassBorderLight,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: selected ? GrowthColors.primary : null,
                    ),
              ),
              const SizedBox(height: GrowthSpacing.xs),
              Text(desc, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
