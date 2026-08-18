import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/discipline/discipline_engine.dart';
import '../../../design_system/design_system.dart';
import '../../focus/focus_providers.dart';

/// 会话结算结果的中转（active → result）
final focusOutcomeProvider = StateProvider<FocusSessionOutcome?>((ref) => null);

/// 专注进行页：单核沉浸 + 引擎状态实时呈现
class FocusActivePage extends ConsumerStatefulWidget {
  const FocusActivePage({super.key});

  @override
  ConsumerState<FocusActivePage> createState() => _FocusActivePageState();
}

class _FocusActivePageState extends ConsumerState<FocusActivePage> {
  Timer? _timer;
  int _remainingMs = 0;
  FocusPhase _phase = FocusPhase.focusing;
  int _distractionCount = 0;
  String? _banner;
  StreamSubscription<DisciplineNotice>? _noticeSub;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(activeFocusProvider);
    if (state is FocusRunning) {
      _running = state;
      _remainingMs = state.planned.inMilliseconds;
      _noticeSub = state.engine.notices.listen(_onNotice);
      _timer =
          Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    }
  }

  FocusRunning? _running;

  void _tick() {
    if (_ending) return;
    final running = _running;
    if (running == null) return;
    setState(() {
      _remainingMs = math.max(0, _remainingMs - 500);
      _phase = running.engine.phase;
      _distractionCount = running.engine.distractionCount;
    });
    if (_remainingMs == 0) {
      _finish('completed');
    }
  }

  void _onNotice(DisciplineNotice notice) {
    if (!mounted) return;
    setState(() {
      _banner = switch (notice.kind) {
        'remind' => notice.message,
        'lock' => '锁屏干预已启动',
        'recovered' => notice.message,
        _ => null,
      };
    });
    if (_banner != null) {
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _banner = null);
      });
    }
  }

  Future<void> _finish(String status) async {
    if (_ending) return;
    _ending = true;
    _timer?.cancel();
    final outcome =
        await ref.read(activeFocusProvider.notifier).stop(status: status);
    if (!mounted) return;
    ref.read(focusOutcomeProvider.notifier).state = outcome;
    context.pushReplacement('/focus/result');
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showGrowthDialog(
      context: context,
      title: '结束本次专注？',
      message: '提前结束也算一次记录，但建议尽量坚持到最后一分钟。',
      confirmLabel: '结束',
      destructive: true,
    );
    if (confirmed == true) {
      await _finish('aborted');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noticeSub?.cancel();
    super.dispose();
  }

  String get _timeText {
    final totalSeconds = (_remainingMs / 1000).ceil();
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeFocusProvider);
    if (state is! FocusRunning) {
      // 会话不存在（如热重启后）：回首页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final planned = state.planned.inMilliseconds;
    final progress = planned <= 0 ? 0.0 : _remainingMs / planned;

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
          child: Column(
            children: [
              const SizedBox(height: GrowthSpacing.lg),
              Text(
                state.mode == FocusMode.abyss ? '深渊专注' : '专注中',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: GrowthSpacing.sm),
              _PhaseChip(phase: _phase, distractionCount: _distractionCount),
              if (_banner != null) ...[
                const SizedBox(height: GrowthSpacing.sm),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: GrowthSpacing.xl),
                  padding: const EdgeInsets.all(GrowthSpacing.sm),
                  decoration: BoxDecoration(
                    color: GrowthColors.abilityFocus.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(GrowthRadii.icon),
                  ),
                  child: Text(
                    _banner!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _FocusRingPainter(progress: progress),
                      ),
                    ),
                    Text(
                      _timeText,
                      style: GrowthType.display.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: GrowthSpacing.xl),
                child: GrowthButton(
                  label: '结束专注',
                  variant: GrowthButtonVariant.secondary,
                  expanded: true,
                  onPressed: _confirmLeave,
                ),
              ),
              const SizedBox(height: GrowthSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.phase, required this.distractionCount});

  final FocusPhase phase;
  final int distractionCount;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      FocusPhase.focusing => ('专注中', GrowthColors.success),
      FocusPhase.distracted => ('已分心，回来吧', GrowthColors.caution),
      FocusPhase.locked => ('等待回归', GrowthColors.abilityFocus),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: GrowthSpacing.xs),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
        const SizedBox(width: GrowthSpacing.md),
        Text(
          '分心 $distractionCount 次',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 6.0;
    final radius = (size.shortestSide - strokeWidth * 2) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = GrowthColors.abilityFocus,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
