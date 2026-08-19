import 'dart:convert';

import 'package:flutter/services.dart';

/// 图片来源（Part 2.5 枚举化，为后期分享接收留扩展点）
enum CaptureSource {
  camera,
  album,
  // futureShare —— 分享接收预留，本期不实现
}

/// 扫描结果（v10：带回落级别）
class ScanResult {
  const ScanResult({required this.path, required this.fallback});

  final String path;

  /// none=检测到纸面 / minarea=旋转矩形回落 / fullframe=全幅内缩（建议手动校准）
  final String fallback;

  bool get needsManualHint => fallback == 'fullframe';
}

/// 文档扫描桥接 —— Kotlin 产事实（OpenCV 四边形检测/透视拉正/匀光）
class ScannerBridge {
  ScannerBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('studygrowth/scanner');

  final MethodChannel _channel;

  /// 自动文档提取（v10 管线 + ROI）。
  /// roi：归一化 [x, y, w, h]（对准引导框），可空。
  Future<ScanResult?> scanDocument(String path, {List<double>? roi}) async {
    try {
      final raw = await _channel.invokeMethod<String>(
        'scanDocument',
        {
          'path': path,
          if (roi != null && roi.length == 4) 'roi': roi,
        },
      );
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final p = json['path']?.toString();
      if (p == null || p.isEmpty) return null;
      return ScanResult(
        path: p,
        fallback: (json['fallback'] ?? 'none').toString(),
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
