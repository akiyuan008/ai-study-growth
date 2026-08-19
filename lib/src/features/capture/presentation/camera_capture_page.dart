import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as ip;
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import '../../../core/bridge/scanner_bridge.dart';
import '../../../design_system/design_system.dart';

final scannerBridgeProvider = Provider<ScannerBridge>((ref) {
  return ScannerBridge();
});

/// 拍照页（v10 夸克式）：暗色相机腔体，独立于 App 浅色主题。
/// 顶栏：返回 | 闪光灯 / 网格（默认开）/ 帮助
/// 中央：对准引导框 + 十字（同时作为 OpenCV 提取 ROI）
/// 底部三槽：最近扫描 | 快门 | 相册+文件导入
class CameraCapturePage extends ConsumerStatefulWidget {
  const CameraCapturePage({super.key});

  @override
  ConsumerState<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends ConsumerState<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  String? _initError;

  FlashMode _flash = FlashMode.off;
  bool _gridOn = true;
  bool _helpExpanded = false;
  bool _guideVisible = true;
  bool _shooting = false;

  /// 本次会话已拍摄/导入的图片（最近扫描）
  final List<String> _sessionShots = [];

  static const _guideWidthRatio = 0.86;
  static const _guideHeightRatio = 0.58;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
    _initCamera();
  }

  Future<void> _loadPrefs() async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _gridOn = prefs.getBool('capture.grid_on') ?? true; // 网格默认开
      // 首次默认显示引导；成功拍题后自动收起（可手动再开）
      _guideVisible = !(prefs.getBool('capture.guide_dismissed') ?? false);
    });
  }

  /// 引导框归一化 ROI 串（传编辑屏作为 OpenCV 感兴趣区域）
  String get _roiQuery {
    const w = _guideWidthRatio;
    const h = _guideHeightRatio;
    final x = ((1 - w) / 2).toStringAsFixed(3);
    final y = ((1 - h) / 2 - 0.03).toStringAsFixed(3);
    return '$x,$y,${w.toStringAsFixed(3)},${h.toStringAsFixed(3)}';
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _initError = '未找到相机';
        });
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _initError = '相机启动失败：$e';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _initializing = true);
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      setState(() => _flash = next);
    } catch (_) {}
  }

  Future<void> _toggleGrid() async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() => _gridOn = !_gridOn);
    await prefs.setBool('capture.grid_on', _gridOn);
  }

  /// 毫秒级快门：takePicture → 压缩归档 → 编辑屏（带 ROI）
  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _shooting) {
      return;
    }
    setState(() => _shooting = true);
    unawaited(HapticFeedback.lightImpact());
    try {
      final file = await controller.takePicture();
      final archived = await archiveImage(file.path);
      if (!mounted) return;
      setState(() => _sessionShots.add(archived));
      // 成功拍题后引导自动收起（下次可手动再开）
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('capture.guide_dismissed', true);
      if (!mounted) return;
      setState(() => _guideVisible = false);
      await context.push(
        '/capture/edit?path=${Uri.encodeComponent(archived)}&source=camera&roi=$_roiQuery',
      );
    } catch (_) {
      // 快门失败静默，允许立即重拍
    } finally {
      if (mounted) setState(() => _shooting = false);
    }
  }

  Future<void> _pickFromAlbum() async {
    final picked = await ip.ImagePicker().pickImage(
      source: ip.ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    final archived = await archiveImage(picked.path);
    if (!mounted) return;
    setState(() => _sessionShots.add(archived));
    await context.push(
      '/capture/edit?path=${Uri.encodeComponent(archived)}&source=album',
    );
  }

  Future<void> _pickFromFile() async {
    // 文件导入：走相册通道（Android 文件选择器对图片场景等价）
    await _pickFromAlbum();
  }

  /// 多页管理：预览 / 删除 / 重排
  void _openMultiPageSheet() {
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => _MultiPageManager(
        shots: _sessionShots,
        onChanged: () => setState(() {}),
        onEdit: (path) async {
          Navigator.of(sheetContext).pop();
          if (!mounted) return;
          await context.push(
            '/capture/edit?path=${Uri.encodeComponent(path)}&source=camera',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- 取景全屏铺满 ----
          if (_initializing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_initError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(GrowthSpacing.xl),
                child: Text(
                  _initError!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (controller != null && controller.value.isInitialized)
            CameraPreview(controller)
          else
            const SizedBox.shrink(),

          // ---- 网格（默认开） ----
          if (_gridOn && controller != null && controller.value.isInitialized)
            IgnorePointer(child: CustomPaint(painter: _GridPainter())),

          // ---- 中央对准引导（OpenCV ROI） ----
          if (_guideVisible)
            Positioned(
              left: mq.size.width * (1 - _guideWidthRatio) / 2,
              top: mq.size.height * ((1 - _guideHeightRatio) / 2 - 0.03),
              width: mq.size.width * _guideWidthRatio,
              height: mq.size.height * _guideHeightRatio,
              child: const _AlignGuide(),
            ),

          // ---- 顶部栏（深色） ----
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: mq.padding.top + GrowthSpacing.sm,
                left: GrowthSpacing.md,
                right: GrowthSpacing.md,
                bottom: GrowthSpacing.sm,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Color(0x00000000)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _DarkIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      _DarkIconButton(
                        icon: _flash == FlashMode.off
                            ? Icons.flash_off_rounded
                            : Icons.flash_on_rounded,
                        active: _flash == FlashMode.torch,
                        onTap: _toggleFlash,
                      ),
                      const SizedBox(width: GrowthSpacing.sm),
                      _DarkIconButton(
                        icon: Icons.grid_on_rounded,
                        active: _gridOn,
                        onTap: _toggleGrid,
                      ),
                      const SizedBox(width: GrowthSpacing.sm),
                      _DarkIconButton(
                        icon: Icons.help_outline_rounded,
                        active: _helpExpanded,
                        onTap: () =>
                            setState(() => _helpExpanded = !_helpExpanded),
                      ),
                    ],
                  ),
                  if (_helpExpanded)
                    Container(
                      margin: const EdgeInsets.only(top: GrowthSpacing.sm),
                      padding: const EdgeInsets.all(GrowthSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(GrowthRadii.icon),
                      ),
                      child: const Text(
                        '把题目放进框内，对准中心 + 号拍摄。\n'
                        '纸张在画面内即可自动提取拉正；没对准也能拍，之后可手动校准。',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.6),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ---- 底部三槽（深色） ----
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: mq.padding.bottom + GrowthSpacing.lg,
                top: GrowthSpacing.md,
                left: GrowthSpacing.lg,
                right: GrowthSpacing.lg,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xE6000000), Color(0x00000000)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左槽：最近扫描
                  _SlotButton(
                    onTap: _sessionShots.isEmpty ? null : _openMultiPageSheet,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(GrowthRadii.icon),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5)),
                            image: _sessionShots.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(_sessionShots.last)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _sessionShots.isEmpty
                              ? const Icon(Icons.photo_library_outlined,
                                  color: Colors.white54, size: 22)
                              : null,
                        ),
                        if (_sessionShots.isNotEmpty)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: GrowthColors.actionAccent,
                                borderRadius:
                                    BorderRadius.circular(GrowthRadii.pill),
                              ),
                              child: Text(
                                '${_sessionShots.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 中槽：大快门（白色圆环）
                  GestureDetector(
                    onTap: _shooting ? null : _shoot,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _shooting
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // 右槽：相册 + 文件导入
                  Row(
                    children: [
                      _SlotButton(
                        onTap: _pickFromAlbum,
                        child: const Icon(Icons.photo_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: GrowthSpacing.sm),
                      _SlotButton(
                        onTap: _pickFromFile,
                        child: const Icon(Icons.insert_drive_file_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 对准引导：圆角框 + 中心十字 + 文案
class _AlignGuide extends StatelessWidget {
  const _AlignGuide();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _GuideFramePainter()),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 十字
            SizedBox(
              width: 34,
              height: 34,
              child: CustomPaint(painter: _CrossPainter()),
            ),
          ],
        ),
        Positioned(
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(GrowthRadii.pill),
            ),
            child: const Text(
              '把题目放进框内，对准 + 号',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.85);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, paint);

    // 四角加粗
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    const len = 26.0;
    final l = 4.0;
    final t = 4.0;
    final r = size.width - 4;
    final b = size.height - 4;
    canvas.drawLine(Offset(l, t), Offset(l + len, t), corner);
    canvas.drawLine(Offset(l, t), Offset(l, t + len), corner);
    canvas.drawLine(Offset(r, t), Offset(r - len, t), corner);
    canvas.drawLine(Offset(r, t), Offset(r, t + len), corner);
    canvas.drawLine(Offset(l, b), Offset(l + len, b), corner);
    canvas.drawLine(Offset(l, b), Offset(l, b - len), corner);
    canvas.drawLine(Offset(r, b), Offset(r - len, b), corner);
    canvas.drawLine(Offset(r, b), Offset(r, b - len), corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), paint);
    canvas.drawLine(Offset(cx, cy - 12), Offset(cx, cy + 12), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 3, 0),
        Offset(size.width * i / 3, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DarkIconButton extends StatelessWidget {
  const _DarkIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GrowthRadii.pill),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: active ? 0.65 : 0.35),
        ),
        child: Icon(
          icon,
          size: 22,
          color: active ? GrowthColors.actionAccent : Colors.white,
        ),
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GrowthRadii.icon),
      child: Padding(
        padding: const EdgeInsets.all(GrowthSpacing.xs),
        child: child,
      ),
    );
  }
}

/// 多页管理：预览 / 删除 / 重排
class _MultiPageManager extends StatefulWidget {
  const _MultiPageManager({
    required this.shots,
    required this.onChanged,
    required this.onEdit,
  });

  final List<String> shots;
  final VoidCallback onChanged;
  final ValueChanged<String> onEdit;

  @override
  State<_MultiPageManager> createState() => _MultiPageManagerState();
}

class _MultiPageManagerState extends State<_MultiPageManager> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本次扫描（${widget.shots.length} 页）',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: GrowthSpacing.xs),
          Text('长按拖动重排，点按进入编辑', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: GrowthSpacing.md),
          Expanded(
            child: widget.shots.isEmpty
                ? Center(
                    child: Text('还没有拍摄内容',
                        style: Theme.of(context).textTheme.bodySmall),
                  )
                : ReorderableListView.builder(
                    itemCount: widget.shots.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final item = widget.shots.removeAt(oldIndex);
                        widget.shots.insert(newIndex, item);
                        widget.onChanged();
                      });
                    },
                    itemBuilder: (context, i) {
                      final path = widget.shots[i];
                      return Padding(
                        key: ValueKey(path),
                        padding:
                            const EdgeInsets.only(bottom: GrowthSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_handle_rounded,
                                size: 18, color: GrowthColors.gray4),
                            const SizedBox(width: GrowthSpacing.sm),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(GrowthRadii.icon),
                              child: Image.file(
                                File(path),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: GrowthSpacing.md),
                            Expanded(
                              child: Text(
                                '第 ${i + 1} 页',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20, color: GrowthColors.primary),
                              onPressed: () => widget.onEdit(path),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: GrowthColors.warning),
                              onPressed: () {
                                setState(() {
                                  widget.shots.removeAt(i);
                                  widget.onChanged();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 图片归档：入库即压缩（长边 1600px、q80，Part 4.1）
Future<String> archiveImage(String sourcePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final captureDir = Directory(p.join(dir.path, 'captures'))
    ..createSync(recursive: true);
  final target = File(p.join(
    captureDir.path,
    'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
  ));
  try {
    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      target.path,
      minWidth: 1600,
      minHeight: 1600,
      quality: 80,
    );
    if (compressed != null) {
      return compressed.path;
    }
  } catch (_) {
    // 压缩失败回落原图复制，不阻塞录入
  }
  await File(sourcePath).copy(target.path);
  return target.path;
}
