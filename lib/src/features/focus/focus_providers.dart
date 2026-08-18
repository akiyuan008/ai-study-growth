import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/bridge/behavior_bridge.dart';
import '../../core/di/providers.dart';
import '../../core/discipline/discipline_engine.dart';
import '../../data/local/app_database.dart';
import '../../data/services/settings_service.dart';
import '../../design_system/growth_theme.dart' show sharedPreferencesProvider;
import 'package:drift/drift.dart' hide Column, Table;

const _uuid = Uuid();

/// 原生桥接（测试可 override 为 FakeMonitorBridge）
final monitorBridgeProvider = Provider<MonitorBridge>((ref) {
  return MonitorBridgeImpl();
});

/// 专注模式
enum FocusMode { normal, abyss }

/// 开始专注的参数
class FocusStartRequest {
  const FocusStartRequest({
    required this.mode,
    required this.planned,
    this.questionIds = const [],
  });

  final FocusMode mode;
  final Duration planned;
  final List<String> questionIds;
}

/// 全局活跃会话控制器：持有引擎句柄与结算结果
class ActiveFocusController extends Notifier<ActiveFocusState> {
  @override
  ActiveFocusState build() => const FocusIdle();

  /// 创建会话、启动引擎
  Future<String> start(FocusStartRequest request) async {
    final db = ref.read(databaseProvider);
    final bridge = ref.read(monitorBridgeProvider);
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.into(db.focusSessions).insert(
          FocusSessionsCompanion.insert(
            id: id,
            mode: Value(request.mode.name),
            questionIds:
                Value('[${request.questionIds.map((q) => '"$q"').join(',')}]'),
            plannedMs: Value(request.planned.inMilliseconds),
            startedAt: now,
          ),
        );

    final settings = SettingsService(ref.read(sharedPreferencesProvider));
    final whitelist = settings.whitelist.toSet();
    final engine = DisciplineEngine(
      db: db,
      bridge: bridge,
      ownPackage: 'com.studygrowth.ai_study_growth',
      // App 分类管理：白名单应用不算分心
      isAllowed: (pkg) => whitelist.contains(pkg),
      remindAfter: request.mode == FocusMode.abyss
          ? const Duration(seconds: 30)
          : const Duration(minutes: 1),
      lockAfter: request.mode == FocusMode.abyss
          ? const Duration(minutes: 2)
          : const Duration(minutes: 5),
      enableLock: true,
    );
    await engine.start(sessionId: id);

    state = FocusRunning(
      sessionId: id,
      engine: engine,
      planned: request.planned,
      mode: request.mode,
    );
    return id;
  }

  /// 结算并返回结果
  Future<FocusSessionOutcome?> stop({required String status}) async {
    final current = state;
    if (current is! FocusRunning) return null;
    final outcome = await current.engine.stop(status: status);
    await current.engine.dispose();
    state = const FocusIdle();
    return outcome;
  }
}

sealed class ActiveFocusState {
  const ActiveFocusState();
}

class FocusIdle extends ActiveFocusState {
  const FocusIdle();
}

class FocusRunning extends ActiveFocusState {
  const FocusRunning({
    required this.sessionId,
    required this.engine,
    required this.planned,
    required this.mode,
  });

  final String sessionId;
  final DisciplineEngine engine;
  final Duration planned;
  final FocusMode mode;
}

final activeFocusProvider =
    NotifierProvider<ActiveFocusController, ActiveFocusState>(
        ActiveFocusController.new);

/// 启动清理：把上次遗留的 active 会话标记为 aborted
Future<void> cleanupStaleFocusSessions(AppDatabase db) async {
  await (db.update(db.focusSessions)..where((t) => t.status.equals('active')))
      .write(FocusSessionsCompanion(
    status: const Value('aborted'),
    endedAt: Value(DateTime.now()),
  ));
}
