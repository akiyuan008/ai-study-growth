import 'package:flutter/services.dart';

/// 图片来源（Part 2.5 枚举化，为后期分享接收留扩展点）
enum CaptureSource {
  camera,
  album,
  // futureShare —— 分享接收预留，本期不实现
}

/// 文档扫描桥接 —— Kotlin 产事实（OpenCV 四边形检测/透视拉正/匀光）
class ScannerBridge {
  ScannerBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('studygrowth/scanner');

  final MethodChannel _channel;

  /// 自动文档提取：成功返回扫描件路径；失败返回 null（Dart 侧回落原图+手动裁剪）
  Future<String?> scanDocument(String path) async {
    try {
      return await _channel.invokeMethod<String>(
        'scanDocument',
        {'path': path},
      );
    } on PlatformException {
      return null;
    }
  }

  /// 手动四角裁剪（归一化坐标 0-1：tl/tr/br/bl）
  Future<String?> cropByPoints(
    String path, {
    required List<double> tl,
    required List<double> tr,
    required List<double> br,
    required List<double> bl,
  }) async {
    try {
      return await _channel.invokeMethod<String>('cropByPoints', {
        'path': path,
        'tl': tl,
        'tr': tr,
        'br': br,
        'bl': bl,
      });
    } on PlatformException {
      return null;
    }
  }

  /// 旋转 90°
  Future<String?> rotate90(String path) async {
    try {
      return await _channel.invokeMethod<String>('rotate90', {'path': path});
    } on PlatformException {
      return null;
    }
  }
}
