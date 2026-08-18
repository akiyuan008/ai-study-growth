import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// 行为事件（Kotlin 事实层的 Dart 视图）
class BehaviorEvent {
  const BehaviorEvent({
    required this.eventType,
    required this.at,
    this.appPackage,
    this.prevPackage,
    this.durationMs,
  });

  final String eventType;
  final DateTime at;
  final String? appPackage;
  final String? prevPackage;
  final int? durationMs;

  factory BehaviorEvent.fromJson(Map<String, dynamic> json) => BehaviorEvent(
        eventType: (json['eventType'] ?? '').toString(),
        at: DateTime.fromMillisecondsSinceEpoch(
          (json['at'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        appPackage: json['appPackage']?.toString(),
        prevPackage: json['prevPackage']?.toString(),
        durationMs: (json['durationMs'] as num?)?.toInt(),
      );

  factory BehaviorEvent.parse(String raw) =>
      BehaviorEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// 原生监控桥接 —— MethodChannel 发指令，EventChannel 收事实。
///
/// 抽象为接口便于测试注入 Fake。
abstract interface class MonitorBridge {
  Stream<BehaviorEvent> get events;
  Future<void> startMonitor();
  Future<void> stopMonitor();
  Future<void> showLock(String message);

  /// Dart 已消费事件，清空原生侧积压
  Future<void> ackEvents();
  Future<bool> isUsageAccessGranted();
  Future<void> openUsageAccessSettings();

  /// 悬浮窗权限设置页
  Future<void> openOverlaySettings();

  /// 应用通知设置页
  Future<void> openNotificationSettings();

  /// 申请通知权限（Android 13+），返回当前是否已授权
  Future<bool> requestNotificationPermission();
}

class MonitorBridgeImpl implements MonitorBridge {
  MonitorBridgeImpl({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _method = methodChannel ?? const MethodChannel('studygrowth/monitor'),
        _event =
            eventChannel ?? const EventChannel('studygrowth/monitor/events');

  final MethodChannel _method;
  final EventChannel _event;

  Stream<BehaviorEvent>? _events;

  @override
  Stream<BehaviorEvent> get events {
    return _events ??= _event
        .receiveBroadcastStream()
        .map((raw) => BehaviorEvent.parse(raw.toString()))
        .handleError((Object _) {
      // 桥接异常不击穿业务层，事件流保持存活
    });
  }

  @override
  Future<void> startMonitor() => _method.invokeMethod('startMonitor');

  @override
  Future<void> stopMonitor() => _method.invokeMethod('stopMonitor');

  @override
  Future<void> showLock(String message) =>
      _method.invokeMethod('showLock', {'message': message});

  @override
  Future<void> ackEvents() => _method.invokeMethod('ackEvents');

  @override
  Future<bool> isUsageAccessGranted() async =>
      await _method.invokeMethod<bool>('isUsageAccessGranted') ?? false;

  @override
  Future<void> openUsageAccessSettings() =>
      _method.invokeMethod('openUsageAccessSettings');

  @override
  Future<void> openOverlaySettings() =>
      _method.invokeMethod('openOverlaySettings');

  @override
  Future<void> openNotificationSettings() =>
      _method.invokeMethod('openNotificationSettings');

  @override
  Future<bool> requestNotificationPermission() async =>
      await _method.invokeMethod<bool>('requestNotificationPermission') ??
      false;
}

/// 测试/桌面环境替身：可编程事件流
class FakeMonitorBridge implements MonitorBridge {
  final StreamController<BehaviorEvent> controller =
      StreamController<BehaviorEvent>.broadcast();

  bool monitorRunning = false;
  bool usageAccessGranted = true;
  int lockShownCount = 0;
  String? lastLockMessage;

  void emit(BehaviorEvent event) => controller.add(event);

  @override
  Stream<BehaviorEvent> get events => controller.stream;

  @override
  Future<void> startMonitor() async => monitorRunning = true;

  @override
  Future<void> stopMonitor() async => monitorRunning = false;

  @override
  Future<void> showLock(String message) async {
    lockShownCount++;
    lastLockMessage = message;
  }

  @override
  Future<void> ackEvents() async {}

  @override
  Future<bool> isUsageAccessGranted() async => usageAccessGranted;

  @override
  Future<void> openUsageAccessSettings() async {}

  @override
  Future<void> openOverlaySettings() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<bool> requestNotificationPermission() async => true;
}
