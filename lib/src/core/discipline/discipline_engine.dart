import 'dart:async';

import 'package:drift/drift.dart' hide Column, Table;

import '../bridge/behavior_bridge.dart';
import '../discipline/focus_math.dart';
import '../../data/local/app_database.dart';

/// 引擎阶段
enum FocusPhase { focusing, distracted, locked }

/// 给 UI 的通知
class DisciplineNotice {
  const DisciplineNotice({required this.kind, this.message = ''});

  /// remind（分心提醒）/ lock（锁屏干预）/ recovered（回归专注）
  final String kind;
  final String message;
}

/// DisciplineEngine —— 自律域状态机（Dart 做决策）。
///
/// 输入：Kotlin 事实层的 [BehaviorEvent] 流
/// 输出：专注区间（focusMath）、分心计数、提醒/锁屏干预、会话结果落库
///
/// MOSS 监督策略（默认阈值）：
/// - 分心 ≥ 1 分钟 → 温和提醒
/// - 分心 ≥ 5 分钟 → 锁屏遮罩（深渊模式阈值更严）
class DisciplineEngine {
  DisciplineEngine({
    required AppDatabase db,
    required MonitorBridge bridge,
    required this.ownPackage,
    bool Function(String package)? isAllowed,
    this.remindAfter = const Duration(minutes: 1),
    this.lockAfter = const Duration(minutes: 5),
    this.enableLock = true,
    DateTime Function()? clock,
  })  : _db = db,
        _bridge = bridge,
        _isAllowed = isAllowed ?? _defaultAllowed,
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final MonitorBridge _bridge;
  final String ownPackage;
  final bool Function(String package) _isAllowed;
  final Duration remindAfter;
  final Duration lockAfter;
  final bool enableLock;
  final DateTime Function() _clock;

  static bool _defaultAllowed(String package) {
    // 系统桌面/系统 UI 短暂经过不算分心
    const allowed = {
      'com.android.launcher',
      'com.android.systemui',
      'android',
    };
    return allowed.contains(package);
  }

  String? _sessionId;
  StreamSubscription<BehaviorEvent>? _sub;
  Timer? _tickTimer;

  final List<FocusSegment> _segments = [];
  DateTime? _segmentStart;
  DateTime? _sessionStart;
  DateTime? _distractionStart;
  int _distractionCount = 0;
  bool _reminded = false;
  bool _lockShown = false;
  FocusPhase _phase = FocusPhase.focusing;

  final _notices = StreamController<DisciplineNotice>.broadcast();
  Stream<DisciplineNotice> get notices => _notices.stream;
  FocusPhase get phase => _phase;
  int get distractionCount => _distractionCount;

  /// 开始监督一个专注会话
  Future<void> start({required String sessionId}) async {
    _sessionId = sessionId;
    _sessionStart = _clock();
    _segmentStart = _sessionStart;
    _phase = FocusPhase.focusing;

    await _bridge.startMonitor();
    _sub = _bridge.events.listen(_onEvent);
    // 升级检查：每 5 秒 tick 一次（测试可直接调用 tick）
    _tickTimer = Timer.periodic(const Duration(seconds: 5), (_) => tick());
  }

  /// 事件处理：只信事实，不猜
  void _onEvent(BehaviorEvent event) {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    switch (event.eventType) {
      case 'app_foreground':
        final pkg = event.appPackage ?? '';
        _persistEvent(sessionId, event);
        if (pkg == ownPackage || _defaultAllowed(pkg) || _isAllowed(pkg)) {
          _returnToFocus(event.at);
        } else {
          _enterDistraction(event.at);
        }
      case 'lock_dismissed':
        _persistEvent(sessionId, event);
        _returnToFocus(event.at);
      default:
        _persistEvent(sessionId, event);
    }
  }

  void _enterDistraction(DateTime at) {
    if (_phase != FocusPhase.focusing) return;
    // 关闭当前专注区间
    final start = _segmentStart;
    if (start != null) {
      _segments.add(FocusSegment(start: start, end: at));
      _segmentStart = null;
    }
    _distractionStart = at;
    _distractionCount++;
    _reminded = false;
    _lockShown = false;
    _phase = FocusPhase.distracted;
    _notices.add(const DisciplineNotice(kind: 'distraction'));
  }

  void _returnToFocus(DateTime at) {
    if (_phase == FocusPhase.focusing) return;
    final wasDistracted =
        _phase == FocusPhase.distracted || _phase == FocusPhase.locked;
    _distractionStart = null;
    _reminded = false;
    _lockShown = false;
    _phase = FocusPhase.focusing;
    _segmentStart = at;
    if (wasDistracted) {
      _notices.add(const DisciplineNotice(
        kind: 'recovered',
        message: '欢迎回来，继续专注',
      ));
    }
  }

  /// 升级检查：提醒 → 锁屏
  void tick() {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    if (_phase != FocusPhase.distracted) return;
    final start = _distractionStart;
    if (start == null) return;

    final distractedFor = _clock().difference(start);

    if (!_reminded && distractedFor >= remindAfter) {
      _reminded = true;
      _notices.add(const DisciplineNotice(
        kind: 'remind',
        message: '你已经离开专注了，回来吧',
      ));
    }

    if (enableLock && !_lockShown && distractedFor >= lockAfter) {
      _lockShown = true;
      _phase = FocusPhase.locked;
      _persistRaw(sessionId, 'lock_shown', _clock());
      unawaited(_bridge.showLock(
        '你已经离开专注 ${distractedFor.inMinutes} 分钟了。\n回来吧，我们继续。',
      ));
      _notices.add(const DisciplineNotice(
        kind: 'lock',
        message: '锁屏干预已触发',
      ));
    }
  }

  /// 结束会话：结算真实专注时长并落库
  Future<FocusSessionOutcome> stop({required String status}) async {
    final now = _clock();
    _tickTimer?.cancel();
    await _sub?.cancel();
    _sub = null;

    // 收尾未关闭的专注区间
    final start = _segmentStart;
    if (start != null) {
      _segments.add(FocusSegment(start: start, end: now));
      _segmentStart = null;
    }

    final focusMs = totalFocusMs(_segments);
    final sessionId = _sessionId;
    if (sessionId != null) {
      await (_db.update(_db.focusSessions)
            ..where((t) => t.id.equals(sessionId)))
          .write(FocusSessionsCompanion(
        status: Value(status),
        endedAt: Value(now),
        focusMs: Value(focusMs),
        distractionCount: Value(_distractionCount),
      ));
      _persistRaw(sessionId, 'session_end', now);
    }

    await _bridge.stopMonitor();
    await _bridge.ackEvents();

    final outcome = FocusSessionOutcome(
      focusMs: focusMs,
      distractionCount: _distractionCount,
      startedAt: _sessionStart ?? now,
      endedAt: now,
    );
    _sessionId = null;
    _segments.clear();
    _distractionCount = 0;
    _phase = FocusPhase.focusing;
    return outcome;
  }

  /// 当前已累积专注毫秒（含进行中的区间）
  int currentFocusMs() {
    var ms = totalFocusMs(_segments);
    final start = _segmentStart;
    if (start != null && _phase == FocusPhase.focusing) {
      ms += _clock().difference(start).inMilliseconds;
    }
    return ms;
  }

  void _persistEvent(String sessionId, BehaviorEvent e) {
    _persistRaw(
      sessionId,
      e.eventType,
      e.at,
      appPackage: e.appPackage,
      durationMs: e.durationMs,
    );
  }

  void _persistRaw(
    String sessionId,
    String eventType,
    DateTime at, {
    String? appPackage,
    int? durationMs,
  }) {
    unawaited(_db.into(_db.focusEvents).insert(
          FocusEventsCompanion.insert(
            sessionId: Value(sessionId),
            eventType: eventType,
            appPackage: Value(appPackage),
            at: at,
            durationMs: Value(durationMs),
          ),
        ));
  }

  Future<void> dispose() async {
    _tickTimer?.cancel();
    await _sub?.cancel();
    await _notices.close();
  }
}

/// 会话结算结果
class FocusSessionOutcome {
  const FocusSessionOutcome({
    required this.focusMs,
    required this.distractionCount,
    required this.startedAt,
    required this.endedAt,
  });

  final int focusMs;
  final int distractionCount;
  final DateTime startedAt;
  final DateTime endedAt;

  int get totalMs => endedAt.difference(startedAt).inMilliseconds;

  /// 专注率 0-1
  double get focusRatio => totalMs <= 0 ? 0 : focusMs / totalMs;
}
