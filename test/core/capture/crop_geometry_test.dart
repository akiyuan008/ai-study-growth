import 'dart:ui';

import 'package:ai_study_growth/src/core/capture/crop_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clampCorners 钳制', () {
    test('越界坐标钳制到 [0,1]', () {
      final clamped = CropGeometry.clampCorners([
        const Offset(-0.1, 0.5),
        const Offset(1.3, -0.2),
        const Offset(0.5, 1.8),
        const Offset(0.2, 0.9),
      ]);
      expect(clamped[0], const Offset(0, 0.5));
      expect(clamped[1], const Offset(1, 0));
      expect(clamped[2], const Offset(0.5, 1));
      expect(clamped[3], const Offset(0.2, 0.9));
    });
  });

  group('矩形四角（标准情形）', () {
    const rect = [
      Offset(0.1, 0.1),
      Offset(0.9, 0.1),
      Offset(0.9, 0.9),
      Offset(0.1, 0.9),
    ];

    test('面积 = 0.64', () {
      expect(CropGeometry.quadArea(rect), closeTo(0.64, 1e-9));
    });

    test('合法四边形', () {
      expect(CropGeometry.isValidQuad(rect), isTrue);
    });

    test('像素包围盒映射（1000x2000）', () {
      final (x, y, w, h) = CropGeometry.boundingPixelRect(rect, 1000, 2000);
      expect(x, 100);
      expect(y, 200);
      expect(w, 800);
      expect(h, 1600);
    });

    test('像素四角映射', () {
      final px = CropGeometry.toPixelCorners(rect, 1000, 2000);
      expect(px[0], const Offset(100, 200));
      expect(px[2], const Offset(900, 1800));
    });
  });

  group('退化四边形（裁剪必失败的输入）', () {
    test('两点重合面积≈0 → 非法', () {
      const degen = [
        Offset(0.5, 0.5),
        Offset(0.5, 0.5),
        Offset(0.6, 0.6),
        Offset(0.4, 0.4),
      ];
      expect(CropGeometry.isValidQuad(degen), isFalse);
    });

    test('顺序错乱的四点也能正确排序', () {
      final sorted = CropGeometry.sortCorners(const [
        Offset(0.9, 0.9), // br
        Offset(0.1, 0.1), // tl
        Offset(0.9, 0.1), // tr
        Offset(0.1, 0.9), // bl
      ]);
      expect(sorted[0], const Offset(0.1, 0.1)); // tl
      expect(sorted[1], const Offset(0.9, 0.1)); // tr
      expect(sorted[2], const Offset(0.9, 0.9)); // br
      expect(sorted[3], const Offset(0.1, 0.9)); // bl
    });
  });

  group('拖拽回归（四边形拖拽几何不崩坏）', () {
    const viewport = Size(400, 800);
    const initial = [
      Offset(0.1, 0.1),
      Offset(0.9, 0.1),
      Offset(0.9, 0.9),
      Offset(0.1, 0.9),
    ];

    test('连续拖拽后所有角仍在 [0,1] 且四边形保持合法', () {
      var corners = initial;
      // 模拟一串真实拖拽位移（含大幅/反向/越界意图）
      final deltas = [
        const Offset(-300, -600), // 左上角往左上拖出屏外
        const Offset(500, 40),
        const Offset(60, 900), // 往下拖出屏外
        const Offset(-80, -120),
        const Offset(40, 55),
      ];
      for (var i = 0; i < deltas.length; i++) {
        corners = CropGeometry.dragCorner(corners, i % 4, deltas[i], viewport);
        for (final c in corners) {
          expect(c.dx, inInclusiveRange(0.0, 1.0));
          expect(c.dy, inInclusiveRange(0.0, 1.0));
        }
      }
      expect(CropGeometry.isValidQuad(corners), isTrue);
    });

    test('拖拽把角拖到极限位置后裁剪框仍可用', () {
      var corners = initial;
      // 把四个角都往角落极限拖
      corners = CropGeometry.dragCorner(
          corners, 0, const Offset(-1000, -1000), viewport);
      corners = CropGeometry.dragCorner(
          corners, 1, const Offset(1000, -1000), viewport);
      corners = CropGeometry.dragCorner(
          corners, 2, const Offset(1000, 1000), viewport);
      corners = CropGeometry.dragCorner(
          corners, 3, const Offset(-1000, 1000), viewport);
      expect(corners[0], const Offset(0, 0));
      expect(corners[1], const Offset(1, 0));
      expect(corners[2], const Offset(1, 1));
      expect(corners[3], const Offset(0, 1));
      expect(CropGeometry.isValidQuad(corners), isTrue);
      expect(CropGeometry.quadArea(corners), closeTo(1.0, 1e-9));
    });

    test('拖拽成共线 → 退化检测拦截', () {
      var corners = initial;
      // 右上角拖到 (0.5,0.5)：delta=(-160, +320)
      corners = CropGeometry.dragCorner(
          corners, 1, const Offset(-160, 320), viewport);
      // 左下角拖到 (0.3,0.3)：delta=(+80, -480)
      corners = CropGeometry.dragCorner(
          corners, 3, const Offset(80, -480), viewport);
      // 四角共线（对角线）→ 面积 0 → 非法
      expect(CropGeometry.isValidQuad(corners), isFalse);
    });
  });

  group('旋转映射', () {
    test('顺时针 90°：newX=oldY, newY=1-oldX', () {
      expect(CropGeometry.rotatePoint90Cw(const Offset(0.2, 0.3)),
          const Offset(0.3, 0.8));
    });

    test('四角旋转 90° 后仍合法且面积不变', () {
      const quad = [
        Offset(0.15, 0.1),
        Offset(0.85, 0.12),
        Offset(0.9, 0.88),
        Offset(0.1, 0.85),
      ];
      final rotated = CropGeometry.rotateCorners90Cw(quad);
      expect(CropGeometry.isValidQuad(rotated), isTrue);
      expect(CropGeometry.quadArea(rotated),
          closeTo(CropGeometry.quadArea(quad), 1e-9));
    });

    test('旋转 4 次回到原点', () {
      const quad = [
        Offset(0.15, 0.1),
        Offset(0.85, 0.12),
        Offset(0.9, 0.88),
        Offset(0.1, 0.85),
      ];
      var cur = quad;
      for (var i = 0; i < 4; i++) {
        cur = CropGeometry.rotateCorners90Cw(cur);
      }
      for (var i = 0; i < 4; i++) {
        expect(cur[i].dx, closeTo(quad[i].dx, 1e-9));
        expect(cur[i].dy, closeTo(quad[i].dy, 1e-9));
      }
    });
  });
}
