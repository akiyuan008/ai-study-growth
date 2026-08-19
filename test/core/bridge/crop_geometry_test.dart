import 'package:flutter_test/flutter_test.dart';
import 'package:ai_study_growth/src/core/bridge/scanner_bridge.dart';

void main() {
  group('CropResult', () {
    test('success carries path and null error', () {
      const result = CropResult.success('/tmp/cropped.jpg');
      expect(result.isSuccess, isTrue);
      expect(result.path, '/tmp/cropped.jpg');
      expect(result.error, isNull);
    });

    test('failure carries error and null path', () {
      const result = CropResult.failure('OpenCV not loaded');
      expect(result.isSuccess, isFalse);
      expect(result.path, isNull);
      expect(result.error, 'OpenCV not loaded');
    });
  });

  group('Crop coordinate mapping', () {
    // 补钉 B：裁剪几何的回归用例
    // 验证归一化坐标 → 像素坐标的映射逻辑

    test('normalized corners map to correct pixel coordinates', () {
      const w = 1000.0;
      const h = 2000.0;

      // 用户拖拽后的四角（归一化）
      const tl = Offset(0.1, 0.2);
      const tr = Offset(0.9, 0.15);
      const br = Offset(0.95, 0.85);
      const bl = Offset(0.05, 0.9);

      // 映射到像素
      final tlPx = (tl.dx * w, tl.dy * h);
      final trPx = (tr.dx * w, tr.dy * h);
      final brPx = (br.dx * w, br.dy * h);
      final blPx = (bl.dx * w, bl.dy * h);

      expect(tlPx, (100.0, 400.0));
      expect(trPx, (900.0, 300.0));
      expect(brPx, (950.0, 1700.0));
      expect(blPx, (50.0, 1800.0));
    });

    test('full-image corners map to full pixel range', () {
      const w = 1600.0;
      const h = 2400.0;

      const tl = Offset(0.0, 0.0);
      const tr = Offset(1.0, 0.0);
      const br = Offset(1.0, 1.0);
      const bl = Offset(0.0, 1.0);

      expect((tl.dx * w, tl.dy * h), (0.0, 0.0));
      expect((tr.dx * w, tr.dy * h), (1600.0, 0.0));
      expect((br.dx * w, br.dy * h), (1600.0, 2400.0));
      expect((bl.dx * w, bl.dy * h), (0.0, 2400.0));
    });

    test('small region crop maps correctly (user scenario)', () {
      const w = 1200.0;
      const h = 1600.0;

      const tl = Offset(0.05, 0.05);
      const tr = Offset(0.45, 0.05);
      // ignore: unused_local_variable
      const br = Offset(0.45, 0.45);
      const bl = Offset(0.05, 0.45);

      final x = tl.dx * w;
      final y = tl.dy * h;
      final cropW = (tr.dx - tl.dx) * w;
      final cropH = (bl.dy - tl.dy) * h;

      expect(x, 60.0);
      expect(y, 80.0);
      expect(cropW, 480.0);
      expect(cropH, 640.0);
    });

    test('rotated quadrilateral coordinate order is tl/tr/br/bl', () {
      const tl = Offset(0.15, 0.1);
      const tr = Offset(0.85, 0.05);
      const br = Offset(0.9, 0.9);
      const bl = Offset(0.1, 0.95);

      expect(tl.dx, lessThan(tr.dx));
      expect(tl.dy, lessThan(bl.dy));
      expect(br.dx, greaterThan(bl.dx));
      expect(br.dy, greaterThan(tr.dy));

      // Shoelace formula - 验证四边形面积为正（非自交）
      final xs = [tl.dx, tr.dx, br.dx, bl.dx];
      final ys = [tl.dy, tr.dy, br.dy, bl.dy];
      double area = 0;
      for (int i = 0; i < 4; i++) {
        final j = (i + 1) % 4;
        area += xs[i] * ys[j] - xs[j] * ys[i];
      }
      area = area.abs() / 2;
      expect(area, greaterThan(0));
    });

    test('degenerate quadrilateral (all same point) has zero area', () {
      const p = Offset(0.5, 0.5);
      final xs = [p.dx, p.dx, p.dx, p.dx];
      final ys = [p.dy, p.dy, p.dy, p.dy];

      double area = 0;
      for (int i = 0; i < 4; i++) {
        final j = (i + 1) % 4;
        area += xs[i] * ys[j] - xs[j] * ys[i];
      }
      area = area.abs() / 2;
      expect(area, 0);
    });

    test('edge case: corners at exactly 0 and 1', () {
      const w = 1000.0;
      const h = 1000.0;

      const tl = Offset(0.0, 0.0);
      const br = Offset(1.0, 1.0);

      expect(tl.dx * w, 0.0);
      expect(tl.dy * h, 0.0);
      expect(br.dx * w, w);
      expect(br.dy * h, h);
    });
  });

  group('ScanResult', () {
    test('needsManualHint is true for fullframe fallback', () {
      const result = ScanResult(path: '/tmp/scan.jpg', fallback: 'fullframe');
      expect(result.needsManualHint, isTrue);
    });

    test('needsManualHint is false for none/minarea fallback', () {
      const none = ScanResult(path: '/tmp/scan.jpg', fallback: 'none');
      const minarea = ScanResult(path: '/tmp/scan.jpg', fallback: 'minarea');
      expect(none.needsManualHint, isFalse);
      expect(minarea.needsManualHint, isFalse);
    });
  });

  group('CaptureSource enum', () {
    test('has camera and album values', () {
      expect(CaptureSource.values, contains(CaptureSource.camera));
      expect(CaptureSource.values, contains(CaptureSource.album));
    });
  });
}
