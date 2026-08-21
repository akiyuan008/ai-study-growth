import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 每日复习提醒通知服务。
///
/// 权限前置说明：开启开关时先弹说明对话框，用户确认后再请求系统通知权限，
/// 避免系统弹窗突兀出现导致误拒。
abstract final class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'review_reminder';
  static const _channelName = '复习提醒';
  static const _channelDesc = '每日到期复习提醒';
  static const _notificationId = 1001;

  static bool _initialized = false;

  /// 启动时初始化（静默失败不阻塞）
  static Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidInit),
        // 点击通知：打开 App（默认启动行为）
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.defaultImportance,
            ),
          );
      _initialized = true;
    } catch (_) {}
  }

  /// 请求通知权限（Android 13+）。返回是否已授权。
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return true;
    }
  }

  /// 每天 [hour]:[minute] 提醒一次（非精确重复调度，省电且免额外权限）
  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required int dueCount,
  }) async {
    try {
      await cancel();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final body = dueCount > 0
          ? '有 $dueCount 道题到期了，趁记忆还热乎，花几分钟巩固一下'
          : '今天的错题本还空着，拍一道错题开始积累吧';
      await _plugin.zonedSchedule(
        _notificationId,
        '智析录 · 复习提醒',
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  /// 取消每日提醒
  static Future<void> cancel() async {
    try {
      await _plugin.cancel(_notificationId);
    } catch (_) {}
  }
}
