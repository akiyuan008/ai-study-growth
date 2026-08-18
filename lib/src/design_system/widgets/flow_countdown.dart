import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'growth_button.dart';

/// 心流专注倒计时 —— 「单核模式」的核心组件。
///
/// 全屏沉浸：隐藏一切无关 UI，只剩时间、环和呼吸般的节奏。
/// 环随剩余时间缓慢消退，把「时间流逝」变成可感知的视觉。
class FlowCountdown extends StatefulWidget {
  const FlowCountdown({
    super.key,
    required this.total,
    required this.onFinished,
    this.onLeave,
    this.title = '专注中',
    this.accent = GrowthColors.flow,
  });

  /// 总时长
  final Duration total;

  /// 自然走完时回调（仅一次）
  final VoidCallback onFinished;

  /// 用户主动提前离开时回调
  final VoidCallback? onLeave;
  final String title;
  final Color accent;

  @override
  State<FlowCountdown> createState() => FlowCountdownState();
}

@visibleForTesting
class FlowCountdownState extends State<FlowCountdown> {
  late int _remainingMs;
  bool _running = true;
  bool _finished = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingMs = widget.total.inMilliseconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (!_running || _finished) return;
    final next = math.max(0, _remainingMs - 250);
    final completed = next == 0;
    setState(() {
      _remainingMs = next;
      if (completed) {
        _finished = true;
        _timer?.cancel();
      }
    });
    // 完成回调放到帧结束后，避免在 setState 期间触发 Navigator 操作
    if (completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished();
      });
    }
  }

  void _togglePause() {
    setState(() => _running = !_running);
  }

  @visibleForTesting
  int get remainingMs => _remainingMs;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeText {
    final totalSeconds = (_remainingMs / 1000).ceil();
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => widget.total.inMilliseconds == 0
      ? 0
      : _remainingMs / widget.total.inMilliseconds;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            const SizedBox(height: GrowthSpacing.xl),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 15,
                letterSpacing: 4,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FlowRingPainter(
                        progress: _progress,
                        accent: widget.accent,
                      ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: GrowthSpacing.xl,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GrowthButton(
                      label: _running ? '暂停' : '继续',
                      variant: GrowthButtonVariant.secondary,
                      icon: _running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onPressed: _finished ? null : _togglePause,
                    ),
                  ),
                  const SizedBox(width: GrowthSpacing.md),
                  Expanded(
                    child: GrowthButton(
                      label: '结束',
                      variant: GrowthButtonVariant.ghost,
                      onPressed: () {
                        if (widget.onLeave != null) widget.onLeave!();
                      },
                    ),
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

class _FlowRingPainter extends CustomPainter {
  _FlowRingPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = 6.0;
    final radius = (size.shortestSide - strokeWidth * 2) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 轨道
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

    // 剩余时间弧（从顶部顺时针消退）
    if (progress > 0) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glow,
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlowRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}
