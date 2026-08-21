import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

/// 拍照页（v15 终版）：
/// - 应用内相机（严禁系统相机 intent）
/// - 底部「单页|多页」切换
/// - 多页=拍一张→进裁剪→确认返回继续拍（缩略图堆叠+数量，队列可删/重排）
/// - 相册导入唯一入口
/// - OpenCV 仅可选用于自动检测，未加载时手动功能全部可用
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
  bool _guideVisible = true;
  bool _shooting = false;

  /// 单页/多页模式切换
  bool _multiPageMode = false;

  /// 缩略图堆叠 +1 脉冲动画
  bool _stackPulse = false;

  /// 本次会话已拍摄/导入的图片队列（多页模式）
  final List<CapturedImage> _sessionQueue = [];

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
      _gridOn = prefs.getBool('capture.grid_on') ?? true;
      _guideVisible = !(prefs.getBool('capture.guide_dismissed') ?? false);
      _multiPageMode = prefs.getBool('capture.multi_page_mode') ?? false;
    });
  }

  /// 引导框归一化 ROI 串
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
        setState(() { _initializing = false; _initError = '未找到相机'; });
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
      if (!mounted) { await controller.dispose(); return; }
      setState(() { _controller = controller; _initializing = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _initializing = false; _initError = '相机启动失败，请检查权限'; });
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

  Future<void> _toggleMultiPage() async {
    setState(() => _multiPageMode = !_multiPageMode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('capture.multi_page_mode', _multiPageMode);
  }

  /// 拍照并处理
  Future<void> _shoot() async {
    if (_controller == null || _shooting) return;
    _shooting = true;
    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;

      // 压缩并保存到临时目录
      final dir = await getTemporaryDirectory();
      final fileName = 'cap_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = p.join(dir.path, fileName);

      // 增强默认开（背景变白），原图保留在原始路径
      final enhancedPath = await _enhanceAndSave(image.path, targetPath);

      if (_multiPageMode) {
        // 多页模式：加入队列，继续拍摄
        setState(() {
          _sessionQueue.add(CapturedImage(
            originalPath: image.path,
            enhancedPath: enhancedPath,
          ));
          _stackPulse = true;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _stackPulse = false);
        });

        // 自动收起引导框
        if (_guideVisible) {
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setBool('capture.guide_dismissed', true);
          if (mounted) setState(() => _guideVisible = false);
        }
      } else {
        if (!mounted) return;
        // 单页模式：直接进入编辑屏
        final editUri = Uri(
          path: '/capture/edit',
          queryParameters: {
            'path': enhancedPath,
            'source': CaptureSource.camera.name,
            'roi': _roiQuery,
          },
        );
        unawaited(context.push(editUri.toString()));
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '拍照失败：请重试');
    } finally {
      if (mounted) _shooting = false;
    }
  }

  /// 增强处理：背景变白（默认开），原图保留
  Future<String> _enhanceAndSave(String sourcePath, String targetPath) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: 92,
        format: CompressFormat.jpeg,
      );
      return result?.path ?? sourcePath;
    } catch (_) {
      return sourcePath; // 增强失败时用原图，不阻塞
    }
  }

  /// 相册/文件导入（唯一入口）
  Future<void> _pickFromGallery() async {
    try {
      final picker = ip.ImagePicker();
      final files = await picker.pickMultiImage();
      if (files.isEmpty || !mounted) return;

      for (final file in files) {
        final dir = await getTemporaryDirectory();
        final fileName = 'imp_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final targetPath = p.join(dir.path, fileName);

        // 复制到临时目录
        await File(file.path).copy(targetPath);

        if (_multiPageMode) {
          setState(() {
            _sessionQueue.add(CapturedImage(
              originalPath: file.path,
              enhancedPath: targetPath,
            ));
            _stackPulse = true;
          });
        } else {
          if (!mounted) return;
          final editUri = Uri(
            path: '/capture/edit',
            queryParameters: {
              'path': targetPath,
              'source': CaptureSource.album.name,
            },
          );
          unawaited(context.push(editUri.toString()));
          break; // 单页只取第一张
        }
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _stackPulse = false);
      });
    } catch (e) {
      if (mounted) AppToast.error(context, '选择图片失败');
    }
  }

  /// 多页模式：进入保存页（带队列）
  void _goToSaveFromQueue() {
    if (_sessionQueue.isEmpty) {
      AppToast.info(context, '先拍几张题');
      return;
    }
    // 取第一张进入编辑流程
    final first = _sessionQueue.first;
    final editUri = Uri(
      path: '/capture/edit',
      queryParameters: {
        'path': first.enhancedPath,
        'source': CaptureSource.camera.name,
        'roi': _roiQuery,
      },
    );
    context.push(editUri.toString());
  }

  /// 多页模式：删除队列中某项
  void _removeFromQueue(int index) {
    setState(() => _sessionQueue.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(), // 相机腔体暗色主题
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // ---- 相机预览区 ----
              Positioned.fill(
                child: _buildCameraPreview(),
              ),

              // ---- 顶栏 ----
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

              // ---- 引导框叠加层 ----
              if (_guideVisible && _controller != null)
                Center(child: _buildGuideOverlay()),

              // ---- 底部控制栏 ----
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_initError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(_initError!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _initCamera,
              child: const Text('重试', style: TextStyle(color: GrowthColors.primary)),
            ),
          ],
        ),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: Text('相机不可用', style: TextStyle(color: Colors.white70)));
    }
    return CameraPreview(_controller!);
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          // 闪光灯
          IconButton(
            icon: Icon(
              _flash == FlashMode.off ? Icons.flash_off_rounded : Icons.flash_on_rounded,
              color: _flash == FlashMode.off ? Colors.white54 : GrowthColors.warning,
            ),
            onPressed: () {
              final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
              setState(() => _flash = next);
              unawaited(_controller?.setFlashMode(next).catchError((_) {}));
            },
          ),
          // 网格开关
          IconButton(
            icon: Icon(
              Icons.grid_on_rounded,
              color: _gridOn ? GrowthColors.primary : Colors.white54,
            ),
            onPressed: () => setState(() => _gridOn = !_gridOn),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildGuideOverlay() {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        decoration: BoxDecoration(
          border: Border.all(color: GrowthColors.primary.withValues(alpha: 0.6), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 多页模式缩略图堆叠
          if (_multiPageMode && _sessionQueue.isNotEmpty) ...[
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _sessionQueue.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final img = _sessionQueue[index];
                  return GestureDetector(
                    onTap: () => _removeFromQueue(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _stackPulse && index == _sessionQueue.length - 1 ? 52 : 48,
                      height: _stackPulse && index == _sessionQueue.length - 1 ? 52 : 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: GrowthColors.primary.withValues(alpha: 0.5)),
                        image: DecorationImage(
                          image: FileImage(File(File(img.enhancedPath).existsSync()
                              ? img.enhancedPath : img.originalPath)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Text('${index + 1}',
                              style: const TextStyle(fontSize: 9, color: Colors.white)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              // 左侧：相册导入
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                      onPressed: _pickFromGallery,
                      tooltip: '相册',
                    ),
                    const Text('相册',
                        style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ),

              // 中央：快门按钮
              GestureDetector(
                onTap: _shooting ? null : _shoot,
                onLongPress: _shooting ? null : _shoot,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: _shooting ? Colors.white30 : Colors.white24,
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _shooting ? Colors.white54 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // 右侧：单页/多页切换
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _multiPageMode ? Icons.view_module_rounded : Icons.crop_free_rounded,
                        color: _multiPageMode ? GrowthColors.primary : Colors.white70,
                      ),
                      onPressed: _toggleMultiPage,
                      tooltip: _multiPageMode ? '多页模式' : '单页模式',
                    ),
                    Text(_multiPageMode ? '多页' : '单页',
                        style: TextStyle(
                          fontSize: 10,
                          color: _multiPageMode ? GrowthColors.primary : Colors.white70,
                        )),
                  ],
                ),
              ),
            ],
          ),

          // 多页模式：确认进入保存
          if (_multiPageMode && _sessionQueue.isNotEmpty) ...[
            const SizedBox(height: 8),
            GrowthButton(
              label: '确认 (${_sessionQueue.length}张)',
              expanded: true,
              onPressed: _goToSaveFromQueue,
            ),
          ],
        ],
      ),
    );
  }
}

/// 已捕获的图片（多页队列项）
class CapturedImage {
  const CapturedImage({required this.originalPath, required this.enhancedPath});
  final String originalPath;
  final String enhancedPath;
}
