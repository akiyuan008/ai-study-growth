import 'dart:convert';

import 'package:flutter/services.dart';

/// 图片来源（Part 2.5 枚举化，为后期分享接收留扩展点）
enum CaptureSource {
  camera,
  album,
}

/// 扫描结果（v10：带回落级别）
class ScanResult {
  const ScanResult({required this.path, required this.fallback});

  final String path;

  /// none=检测到纸面 / minarea=旋转矩形回落 / fullframe=全幅内缩（建议手动校准）
  final String fallback;

  bool get needsManualHint => fallback == 'fullframe';
}

/// 裁剪结果：成功返回路径，失败返回具体原因（补钉 B）
class CropResult {
  const CropResult.success(this.path)
      : error = null;
  const CropResult.failure(this.error) : path = null;

  final String? path;
  final String? error;

  bool get isSuccess => path != null;
}

/// 文档扫描桥接 —— Kotlin 产事实（OpenCV 四边形检测/透视拉正/匀光）
class ScannerBridge {
  ScannerBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('studygrowth/scanner');

  final MethodChannel _channel;

  /// 自动文档提取（v10 管线 + ROI）。
  /// roi：归一化 [x, y, w, h]（对准引导框），可空。
  Future<ScanResult?> scanDocument(String path, {List<double>? roi}) async {
    final args = <String, dynamic>{'path': path};
    if (roi != null) args['roi'] = roi;
    try {
      final raw = await _channel.invokeMethod<String>('scanDocument', args);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ScanResult(
        path: json['path'] as String,
        fallback: json['fallback'] as String? ?? 'none',
      );
    } on PlatformException catch (e) {
      // 补钉 B：不再静默吞错，向上传递具体原因
      throw ScannerException('scan_failed', e.message ?? e.code);
    } on FormatException {
      return null;
    }
  }

  /// OpenCV 版本号
  Future<String> getVersion() async {
    try {
      return await _channel.invokeMethod<String>('getVersion') ?? 'unavailable';
    } on PlatformException {
      return 'unavailable';
    }
  }

  /// 手动四角裁剪（归一化坐标 0-1：tl/tr/br/bl）
  /// 补钉 B：返回 CropResult 含具体失败原因，不静默 null
  Future<CropResult> cropByPoints(
    String path, {
    required List<double> tl,
    required List<double> tr,
    required List<double> br,
    required List<double> bl,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('cropByPoints', {
        'path': path,
        'tl': tl,
        'tr': tr,
        'br': br,
        'bl': bl,
      });
      if (result == null) {
        return const CropResult.failure('原生层返回空结果');
      }
      final status = result['status'] as String?;
      if (status == 'success') {
        final outPath = result['path'] as String?;
        if (outPath != null && outPath.isNotEmpty) {
          return CropResult.success(outPath);
        }
        return const CropResult.failure('裁剪成功但路径为空');
      }
      // 返回原生层的具体失败原因
      final reason = result['error'] as String? ?? '未知原因';
      return CropResult.failure(reason);
    } on PlatformException catch (e) {
      // 补钉 B：区分类型——MissingPlugin vs 真正异常
      return CropResult.failure('插件异常: ${e.code} ${e.message ?? ''}');
    } catch (e) {
      return CropResult.failure('意外错误: $e');
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

/// 扫描器异常（含具体原因，补钉 B）
class ScannerException implements Exception {
  const ScannerException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ScannerException($code): $message';
}
