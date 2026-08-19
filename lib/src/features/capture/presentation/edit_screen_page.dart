import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/bridge/scanner_bridge.dart';
import '../../../design_system/design_system.dart';
import 'camera_capture_page.dart';

/// 统一编辑屏（Part 2.3）：
/// 拍摄/导入一律进入——可拖拽四角裁剪框 + 旋转 + 一键自动校准。
class EditScreenPage extends ConsumerStatefulWidget {
  const EditScreenPage({
    super.key,
    required this.path,
    required this.source,
    this.roi,
  });

  final String path;
  final CaptureSource source;

  /// 拍照页对准引导框传来的归一化 ROI [x, y, w, h]
  final List<double>? roi;

  @override
  ConsumerState<EditScreenPage> createState() => _EditScreenPageState();
}

class _EditScreenPageState extends ConsumerState<EditScreenPage> {
  late String _currentPath;

  /// 四角归一化坐标（0-1）
  late List<Offset> _corners;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.path;
    _corners = [
      const Offset(0.06, 0.08),
      const Offset(0.94, 0.08),
      const Offset(0.94, 0.92),
      const Offset(0.06, 0.92),
    ];
    // 进场自动尝试一次文档提取（失败不阻塞，回落手动裁剪）
    _autoCorrect(silent: true);
  }

  Future<void> _autoCorrect({bool silent = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final scanner = ref.read(scannerBridgeProvider);
    final result = await scanner.scanDocument(_currentPath, roi: widget.roi);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result != null) {
        _currentPath = result.path;
        // 自动校准成功后裁剪框复位（已拉正，无需再裁）
        _corners = [
          const Offset(0.02, 0.02),
          const Offset(0.98, 0.02),
          const Offset(0.98, 0.98),
          const Offset(0.02, 0.98),
        ];
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.needsManualHint
                    ? '未检测到纸面边界，已按全幅处理，建议手动校准'
                    : '已自动提取纸面并拉正',
              ),
            ),
          );
        }
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('校准没成功，请手动调整裁剪框，或直接使用原图')),
        );
      }
    });
  }

  Future<void> _rotate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final scanner = ref.read(scannerBridgeProvider);
    final result = await scanner.rotate90(_currentPath);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result != null) _currentPath = result;
    });
  }

  Future<void> _crop() async {
    if (_busy) return;
    setState(() => _busy = true);
    final scanner = ref.read(scannerBridgeProvider);
    final result = await scanner.cropByPoints(
      _currentPath,
      tl: [_corners[0].dx, _corners[0].dy],
      tr: [_corners[1].dx, _corners[1].dy],
      br: [_corners[2].dx, _corners[2].dy],
      bl: [_corners[3].dx, _corners[3].dy],
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result != null) {
        _currentPath = result;
        _corners = [
          const Offset(0.02, 0.02),
          const Offset(0.98, 0.02),
          const Offset(0.98, 0.98),
          const Offset(0.02, 0.98),
        ];
      }
    });
  }

  /// 使用原图：放弃处理结果，回到最初拍摄的图
  Future<void> _useOriginal() async {
    setState(() {
      _currentPath = widget.path;
      _corners = [
        const Offset(0.06, 0.08),
        const Offset(0.94, 0.08),
        const Offset(0.94, 0.92),
        const Offset(0.06, 0.92),
      ];
    });
  }

  Future<void> _confirm() async {
    final archived = await archiveImage(_currentPath);
    if (!mounted) return;
    context.pushReplacement(
      '/capture/save?path=${Uri.encodeComponent(archived)}&source=${widget.source.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GrowthSpacing.md,
                vertical: GrowthSpacing.sm,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(GrowthRadii.icon),
                    child: const Padding(
                      padding: EdgeInsets.all(GrowthSpacing.sm),
                      child: GrowthIcon(
                        type: GrowthIconType.backArrow,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '调整图片',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(GrowthSpacing.md),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(GrowthRadii.icon),
                            child: Image.file(
                              File(_currentPath),
                              fit: BoxFit.contain,
                            ),
                          ),
                          // 裁剪框
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _CropOverlayPainter(corners: _corners),
                            ),
                          ),
                          // 四角拖拽手柄
                          for (var i = 0; i < 4; i++)
                            Positioned(
                              left: _corners[i].dx * constraints.maxWidth - 22,
                              top: _corners[i].dy * constraints.maxHeight - 22,
                              child: GestureDetector(
                                onPanUpdate: (d) {
                                  setState(() {
                                    final nx = (_corners[i].dx +
                                            d.delta.dx / constraints.maxWidth)
                                        .clamp(0.0, 1.0);
                                    final ny = (_corners[i].dy +
                                            d.delta.dy / constraints.maxHeight)
                                        .clamp(0.0, 1.0);
                                    _corners[i] = Offset(nx, ny);
                                  });
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: GrowthColors.actionAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (_busy)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // 工具行：自动校准 / 旋转 / 裁剪
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GrowthSpacing.lg,
                vertical: GrowthSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ToolButton(
                    icon: Icons.auto_fix_high_rounded,
                    label: '自动校准',
                    onTap: () => _autoCorrect(),
                  ),
                  _ToolButton(
                    icon: Icons.rotate_90_degrees_ccw_rounded,
                    label: '旋转',
                    onTap: _rotate,
                  ),
                  _ToolButton(
                    icon: Icons.crop_rounded,
                    label: '裁剪',
                    onTap: _crop,
                  ),
                  _ToolButton(
                    icon: Icons.image_outlined,
                    label: '使用原图',
                    onTap: _useOriginal,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(GrowthSpacing.lg),
              child: GrowthButton(
                label: '下一步',
                expanded: true,
                onPressed: _busy ? null : _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GrowthRadii.icon),
      child: Padding(
        padding: const EdgeInsets.all(GrowthSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.corners});

  final List<Offset> corners;

  @override
  void paint(Canvas canvas, Size size) {
    // 遮罩（框外变暗）
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()
      ..moveTo(corners[0].dx * size.width, corners[0].dy * size.height)
      ..lineTo(corners[1].dx * size.width, corners[1].dy * size.height)
      ..lineTo(corners[2].dx * size.width, corners[2].dy * size.height)
      ..lineTo(corners[3].dx * size.width, corners[3].dy * size.height)
      ..close();
    outer.addPath(inner, Offset.zero);
    canvas.drawPath(
      outer,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver,
    );
    // 框线
    canvas.drawPath(
      inner,
      Paint()
        ..color = GrowthColors.actionAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.corners != corners;
}
