import 'package:flutter/material.dart';

import '../tokens.dart';

/// 统一 Toast 服务（Part 1.1）：
/// - 成功/提示 2-2.5s；错误 4s 且可点按提前消失
/// - 零无限期 SnackBar
/// - 同消息 2s 内去重
enum ToastKind { success, info, error }

/// 全局 ScaffoldMessenger 键：toast 随路由清理，禁跨页残留
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

abstract final class AppToast {
  /// 路由切换时清理残留 toast
  static void clearAll() {
    appMessengerKey.currentState?.clearSnackBars();
    _lastMessage = null;
  }

  static const Duration _successDuration = Duration(milliseconds: 2200);
  static const Duration _errorDuration = Duration(seconds: 4);
  static const Duration _dedupeWindow = Duration(seconds: 2);

  static String? _lastMessage;
  static DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  static void show(BuildContext context, String message,
      {ToastKind kind = ToastKind.info}) {
    final now = DateTime.now();
    if (_lastMessage == message && now.difference(_lastAt) < _dedupeWindow) {
      return; // 同消息去重
    }
    _lastMessage = message;
    _lastAt = now;

    final messenger =
        appMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final isError = kind == ToastKind.error;
    final color = switch (kind) {
      ToastKind.success => GrowthColors.success,
      ToastKind.info => GrowthColors.primary,
      ToastKind.error => GrowthColors.caution,
    };

    final snack = SnackBar(
      content: Row(
        children: [
          Icon(
            switch (kind) {
              ToastKind.success => Icons.check_circle_rounded,
              ToastKind.info => Icons.info_rounded,
              ToastKind.error => Icons.error_rounded,
            },
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
      duration: isError ? _errorDuration : _successDuration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GrowthRadii.icon),
      ),
      // 错误 toast 可点按提前消失（SnackBar 本身支持点击关闭区域）
      action: isError
          ? SnackBarAction(
              label: '知道了',
              textColor: color,
              onPressed: () => messenger.hideCurrentSnackBar(),
            )
          : null,
    );
    messenger.showSnackBar(snack);
  }

  static void success(BuildContext context, String message) =>
      show(context, message, kind: ToastKind.success);

  static void info(BuildContext context, String message) =>
      show(context, message, kind: ToastKind.info);

  static void error(BuildContext context, String message) =>
      show(context, message, kind: ToastKind.error);
}
