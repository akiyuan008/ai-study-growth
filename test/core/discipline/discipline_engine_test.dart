import 'package:ai_study_growth/src/core/bridge/behavior_bridge.dart';
import 'package:ai_study_growth/src/core/discipline/discipline_engine.dart';
import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:drift/drift.dart' hide Column, Table, isNotNull;
import 'package:flutter_test/flutter_test.dart';

const ownPackage = 'com.studygrowth.ai_study_growth';

void main() {
  late AppDatabase db;
  late FakeMonitorBridge bridge;
  late DateTime fakeNow;

  DisciplineEngine buildEngine({
    Duration remindAfter = const Duration(minutes: 1),
    Duration lockAfter = const Duration(minutes: 5),
    bool enableLock = true,
  }) {
    return DisciplineEngine(
      db: db,
      bridge: bridge,
      ownPackage: ownPackage,
      remindAfter: remindAfter,
      lockAfter: lockAfter,
      enableLock: enableLock,
      clock: () => fakeNow,
    );
  }

  BehaviorEvent foreground(String pkg, {DateTime? at}) => BehaviorEvent(
        eventType: 'app_foreground',
        appPackage: pkg,
        at: at ?? fakeNow,
      );

  Future<String> seedSession() async {
    const id = 'fs-test';
    await db.into(db.focusSessions).insert(
          FocusSessionsCompanion.insert(
            id: id,
            startedAt: fakeNow,
            plannedMs: const Value(25 * 60 * 1000),
          ),
        );
    return id;
  }

  /// 等待广播流的 microtask 投递完成
  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    db = openAppDatabaseMemory();
    bridge = FakeMonitorBridge();
    fakeNow = DateTime(2026, 8, 18, 10);
  });

  tearDown(() async {
    await db.close();
  });

  test('纯净会话：全程专注，focusMs = 总时长', () async {
    final engine = buildEngine();
    final id = await seedSession();
    await engine.start(sessionId: id);

    fakeNow = fakeNow.add(const Duration(minutes: 25));
    final outcome = await engine.stop(status: 'completed');

    expect(outcome.focusMs, 25 * 60 * 1000);
    expect(outcome.distractionCount, 0);
    expect(outcome.focusRatio, closeTo(1.0, 0.001));

    final row = await (db.select(db.focusSessions)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.status, 'completed');
    expect(row.focusMs, 25 * 60 * 1000);
  });

  test('切出 2 分钟再回来：该段不计入专注', () async {
    final engine = buildEngine();
    final id = await seedSession();
    await engine.start(sessionId: id);

    // 专注 10 分钟
    fakeNow = fakeNow.add(const Duration(minutes: 10));
    // 切到视频 App
    bridge.emit(foreground('com.example.video'));
    await flush();
    expect(engine.phase, FocusPhase.distracted);
    expect(engine.distractionCount, 1);

    // 分心 2 分钟后回到本 App
    fakeNow = fakeNow.add(const Duration(minutes: 2));
    bridge.emit(foreground(ownPackage));
    await flush();
    expect(engine.phase, FocusPhase.focusing);

    // 再专注 8 分钟
    fakeNow = fakeNow.add(const Duration(minutes: 8));
    final outcome = await engine.stop(status: 'completed');

    expect(outcome.focusMs, 18 * 60 * 1000);
    expect(outcome.distractionCount, 1);
  });

  test('MOSS 策略：1 分钟提醒，5 分钟锁屏，解锁后回归', () async {
    final engine = buildEngine();
    final id = await seedSession();
    await engine.start(sessionId: id);

    bridge.emit(foreground('com.example.video'));
    await flush();
    final notices = <String>[];
    engine.notices.listen((n) => notices.add(n.kind));

    // 30 秒：无事发生
    fakeNow = fakeNow.add(const Duration(seconds: 30));
    engine.tick();
    expect(notices, isEmpty);
    expect(bridge.lockShownCount, 0);

    // 61 秒：提醒
    fakeNow = fakeNow.add(const Duration(seconds: 31));
    engine.tick();
    await flush();
    expect(notices, contains('remind'));

    // 5 分半：锁屏
    fakeNow = fakeNow.add(const Duration(seconds: 240));
    engine.tick();
    expect(bridge.lockShownCount, 1);
    expect(engine.phase, FocusPhase.locked);

    // 用户解锁回归
    fakeNow = fakeNow.add(const Duration(seconds: 10));
    bridge.emit(BehaviorEvent(eventType: 'lock_dismissed', at: fakeNow));
    await flush();
    expect(engine.phase, FocusPhase.focusing);
  });

  test('锁屏解锁事件让引擎回归专注', () async {
    final engine = buildEngine(
      remindAfter: const Duration(seconds: 1),
      lockAfter: const Duration(seconds: 2),
    );
    final id = await seedSession();
    await engine.start(sessionId: id);

    bridge.emit(foreground('com.example.video'));
    await flush();
    fakeNow = fakeNow.add(const Duration(seconds: 3));
    engine.tick();
    expect(engine.phase, FocusPhase.locked);

    fakeNow = fakeNow.add(const Duration(seconds: 5));
    bridge.emit(BehaviorEvent(eventType: 'lock_dismissed', at: fakeNow));
    await flush();
    expect(engine.phase, FocusPhase.focusing);

    fakeNow = fakeNow.add(const Duration(minutes: 1));
    final outcome = await engine.stop(status: 'completed');
    // 前 0 秒专注（立即切出）+ 解锁后 1 分钟
    expect(outcome.focusMs, 60 * 1000);
  });

  test('白名单应用经过不算分心', () async {
    final engine = buildEngine();
    final id = await seedSession();
    await engine.start(sessionId: id);

    bridge.emit(foreground('com.android.systemui'));
    await flush();
    expect(engine.phase, FocusPhase.focusing);
    expect(engine.distractionCount, 0);

    fakeNow = fakeNow.add(const Duration(minutes: 5));
    final outcome = await engine.stop(status: 'completed');
    expect(outcome.focusMs, 5 * 60 * 1000);
  });

  test('关闭锁屏（深渊前温和模式）：只提醒不锁', () async {
    final engine = buildEngine(enableLock: false);
    final id = await seedSession();
    await engine.start(sessionId: id);

    bridge.emit(foreground('com.example.video'));
    await flush();
    fakeNow = fakeNow.add(const Duration(minutes: 10));
    engine.tick();

    expect(bridge.lockShownCount, 0);
    expect(engine.phase, FocusPhase.distracted);
    await engine.stop(status: 'aborted');
  });

  test('分心期间的行为事实落库', () async {
    final engine = buildEngine();
    final id = await seedSession();
    await engine.start(sessionId: id);

    bridge.emit(foreground('com.example.video'));
    await flush();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final events = await db.select(db.focusEvents).get();
    expect(
      events.where((e) =>
          e.eventType == 'app_foreground' &&
          e.appPackage == 'com.example.video'),
      hasLength(1),
    );
    expect(events.every((e) => e.sessionId == id), isTrue);
    await engine.stop(status: 'aborted');
  });
}
