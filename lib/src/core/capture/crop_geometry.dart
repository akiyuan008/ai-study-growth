import 'dart:math' as math;
import 'dart:ui';

/// 裁剪几何纯函数（可单测）。
///
/// 负责：归一化四角的钳制/合法性/像素映射/旋转映射/拖拽模拟。
/// 编辑屏拖拽与原生裁剪调用前后都过这层，保证坐标永远合法。
abstract final class CropGeometry {
  /// 四角钳制到 [0,1]（防越界导致原生裁剪失败）
  static List<Offset> clampCorners(List<Offset> corners) {
    return corners
        .map((c) => Offset(c.dx.clamp(0.0, 1.0), c.dy.clamp(0.0, 1.0)))
        .toList();
  }

  /// 四边形面积（鞋带公式，归一化坐标下为 0-1 的比例面积）
  static double quadArea(List<Offset> corners) {
    if (corners.length != 4) return 0;
    var sum = 0.0;
    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2;
  }

  /// 合法四边形：面积 ≥ 阈值（过小视为退化，裁剪必失败）
  static bool isValidQuad(List<Offset> corners, {double minArea = 0.002}) {
    return corners.length == 4 && quadArea(corners) >= minArea;
  }

  /// 模拟一次拖拽：某角按像素位移移动后钳制回 [0,1]
  static List<Offset> dragCorner(
    List<Offset> corners,
    int index,
    Offset pixelDelta,
    Size viewport,
  ) {
    final next = List<Offset>.from(corners);
    final nx =
        (corners[index].dx + pixelDelta.dx / viewport.width).clamp(0.0, 1.0);
    final ny =
        (corners[index].dy + pixelDelta.dy / viewport.height).clamp(0.0, 1.0);
    next[index] = Offset(nx, ny);
    return next;
  }

  /// 归一化四角 → 像素包围盒（回落矩形裁剪用）
  static (int x, int y, int w, int h) boundingPixelRect(
    List<Offset> corners,
    int imgWidth,
    int imgHeight,
  ) {
    final clamped = clampCorners(corners);
    final xs = clamped.map((c) => c.dx).toList();
    final ys = clamped.map((c) => c.dy).toList();
    final x0 = (xs.reduce(math.min) * imgWidth).floor().clamp(0, imgWidth);
    final y0 = (ys.reduce(math.min) * imgHeight).floor().clamp(0, imgHeight);
    final x1 = (xs.reduce(math.max) * imgWidth).ceil().clamp(0, imgWidth);
    final y1 = (ys.reduce(math.max) * imgHeight).ceil().clamp(0, imgHeight);
    return (x0, y0, math.max(1, x1 - x0), math.max(1, y1 - y0));
  }

  /// 归一化四角 → 像素四角
  static List<Offset> toPixelCorners(
    List<Offset> corners,
    int imgWidth,
    int imgHeight,
  ) {
    return clampCorners(corners)
        .map((c) => Offset(c.dx * imgWidth, c.dy * imgHeight))
        .toList();
  }

  /// 任意顺序四点 → tl/tr/br/bl
  static List<Offset> sortCorners(List<Offset> corners) {
    if (corners.length != 4) return corners;
    final sums = corners.map((c) => c.dx + c.dy).toList();
    final diffs = corners.map((c) => c.dy - c.dx).toList();
    final tl = corners[sums.indexOf(sums.reduce(math.min))];
    final br = corners[sums.indexOf(sums.reduce(math.max))];
    final tr = corners[diffs.indexOf(diffs.reduce(math.min))];
    final bl = corners[diffs.indexOf(diffs.reduce(math.max))];
    return [tl, tr, br, bl];
  }

  /// 图片顺时针旋转 90° 后，原图上某归一化点的新归一化坐标
  static Offset rotatePoint90Cw(Offset p) {
    return Offset(p.dy, 1 - p.dx);
  }

  /// 四角随图片顺时针旋转 90°，并重排为 tl/tr/br/bl
  static List<Offset> rotateCorners90Cw(List<Offset> corners) {
    final rotated = corners.map(rotatePoint90Cw).toList();
    return sortCorners(rotated);
  }
}
