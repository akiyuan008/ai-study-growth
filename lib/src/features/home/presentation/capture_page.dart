import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../design_system/design_system.dart';
import '../../learning/learning_providers.dart';

/// 拍题页：单核入口——拍照或选图，裁剪后进入解析队列
class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key});

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 90,
      );
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '框选题目区域',
            toolbarColor: GrowthColors.surfaceDark,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
        ],
      );
      final sourceFile =
          cropped != null ? File(cropped.path) : File(picked.path);

      // 归档到应用目录
      final dir = await getApplicationDocumentsDirectory();
      final captureDir = Directory(p.join(dir.path, 'captures'))
        ..createSync(recursive: true);
      final target = File(p.join(
        captureDir.path,
        'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      await sourceFile.copy(target.path);

      if (!mounted) return;
      final jobId =
          await ref.read(analysisPipelineProvider).submit(target.path);

      if (!mounted) return;
      context.pop();
      unawaited(context.push('/analysis?focus=$jobId'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍题失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('拍题')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(GrowthSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.document_scanner_rounded,
                size: 88,
                color: GrowthColors.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: GrowthSpacing.lg),
              Text(
                '把错题拍下来\nAI 会帮你拆题、解析、找错因',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: GrowthSpacing.xl),
              GrowthButton(
                label: _busy ? '处理中' : '拍照',
                icon: Icons.camera_alt_rounded,
                expanded: true,
                loading: _busy,
                onPressed: () => _pick(ImageSource.camera),
              ),
              const SizedBox(height: GrowthSpacing.md),
              GrowthButton(
                label: '从相册选择',
                icon: Icons.photo_library_rounded,
                variant: GrowthButtonVariant.secondary,
                expanded: true,
                onPressed: () => _pick(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
