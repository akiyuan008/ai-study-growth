import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/bridge/scanner_bridge.dart';
import '../../../design_system/design_system.dart';

final scannerBridgeProvider = Provider<ScannerBridge>((ref) {
  return ScannerBridge();
});

/// 应用内相机（Part 2.1）：
/// 自建取景框 + 毫秒级快门 + 连拍缩略图条 + 相册导入并排。
/// 严禁拉起系统相机 intent。
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

  /// 本次会话已拍摄的图片（连拍缩略图条）
  final List<String> _shots = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
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
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// 毫秒级快门：直接 takePicture，不进入任何确认流程
  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() => _shots.add(file.path));
      // 每张都走统一编辑屏（Part 2.3）
      await context.push(
          '/capture/edit?path=${Uri.encodeComponent(file.path)}&source=camera');
    } catch (_) {
      // 快门失败静默，允许立即重拍
    }
  }

  /// 相册导入（与快门并排）
  Future<void> _pickFromAlbum() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    setState(() => _shots.add(picked.path));
    await context.push(
        '/capture/edit?path=${Uri.encodeComponent(picked.path)}&source=album');
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部工具行
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
                    '拍题',
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
            // 取景框
            Expanded(
              child: _initializing
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _initError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(GrowthSpacing.xl),
                            child: Text(
                              _initError!,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : controller == null || !controller.value.isInitialized
                          ? const SizedBox.shrink()
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(controller),
                                // 取景框参考线（三分构图）
                                IgnorePointer(
                                  child: CustomPaint(
                                    painter: _ViewfinderPainter(),
                                  ),
                                ),
                              ],
                            ),
            ),
            // 连拍缩略图条
            if (_shots.isNotEmpty)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: GrowthSpacing.md,
                    vertical: GrowthSpacing.sm,
                  ),
                  itemCount: _shots.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: GrowthSpacing.sm),
                  itemBuilder: (context, i) => InkWell(
                    onTap: () => context.push(
                      '/capture/edit?path=${Uri.encodeComponent(_shots[i])}&source=camera',
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(GrowthRadii.icon),
                      child: Image.file(
                        File(_shots[i]),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            // 快门行：相册导入与快门并排
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GrowthSpacing.xl,
                vertical: GrowthSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 相册导入
                  _CircleButton(
                    icon: Icons.photo_library_rounded,
                    onTap: _pickFromAlbum,
                    size: 52,
                  ),
                  // 主快门
                  GestureDetector(
                    onTap: _shoot,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFB25E),
                              GrowthColors.actionAccent
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x59FF9F43),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 占位（对称）
                  const SizedBox(width: 52),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GrowthRadii.pill),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

/// 取景参考线：三分构图 + 四角框
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    // 三分线
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
    // 四角框
    final corner = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    const m = 20.0;
    // 左上
    canvas.drawLine(const Offset(m, m), const Offset(m + len, m), corner);
    canvas.drawLine(const Offset(m, m), const Offset(m, m + len), corner);
    // 右上
    canvas.drawLine(
        Offset(size.width - m, m), Offset(size.width - m - len, m), corner);
    canvas.drawLine(
        Offset(size.width - m, m), Offset(size.width - m, m + len), corner);
    // 左下
    canvas.drawLine(
        Offset(m, size.height - m), Offset(m + len, size.height - m), corner);
    canvas.drawLine(
        Offset(m, size.height - m), Offset(m, size.height - m - len), corner);
    // 右下
    canvas.drawLine(
      Offset(size.width - m, size.height - m),
      Offset(size.width - m - len, size.height - m),
      corner,
    );
    canvas.drawLine(
      Offset(size.width - m, size.height - m),
      Offset(size.width - m, size.height - m - len),
      corner,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 图片归档工具：入库即压缩（长边 1600px、q80，Part 4.1），存到 captures 目录
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
