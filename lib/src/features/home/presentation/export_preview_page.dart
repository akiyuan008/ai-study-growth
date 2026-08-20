import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/di/providers.dart';
import '../../../core/export/question_pdf_exporter.dart';
import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../capture/presentation/camera_capture_page.dart';

/// 导出上下文（多选 ids + 打印设置）
class ExportContext {
  const ExportContext({required this.ids, this.settings = const PdfSettings()});

  final List<String> ids;
  final PdfSettings settings;
}

final exportContextProvider = StateProvider<ExportContext?>((ref) => null);

/// 打印设置 sheet（v14：字号/图片内容/含举一反三）
void showPdfSettingsSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<String> ids,
}) {
  final initial =
      ref.read(exportContextProvider)?.settings ?? const PdfSettings();
  var largeFont = initial.largeFont;
  var useEnhanced = initial.useEnhanced;
  var includeExercises = initial.includeExercises;

  showGrowthSheet<void>(
    context: context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('打印设置', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: GrowthSpacing.md),
          _OptionRow(
            title: '字号',
            value: largeFont ? '大号' : '标准',
            onTap: () => setSheet(() => largeFont = !largeFont),
          ),
          _OptionRow(
            title: '图片内容',
            value: useEnhanced ? '增强图（扫描白）' : '原图',
            onTap: () => setSheet(() => useEnhanced = !useEnhanced),
          ),
          _OptionRow(
            title: '附举一反三',
            value: includeExercises ? '开' : '关',
            onTap: () => setSheet(() => includeExercises = !includeExercises),
          ),
          const SizedBox(height: GrowthSpacing.md),
          GrowthButton(
            label: '预览白纸页面',
            expanded: true,
            onPressed: () {
              ref.read(exportContextProvider.notifier).state = ExportContext(
                ids: ids,
                settings: PdfSettings(
                  largeFont: largeFont,
                  useEnhanced: useEnhanced,
                  includeExercises: includeExercises,
                ),
              );
              Navigator.of(sheetContext).pop();
              context.push('/export/preview');
            },
          ),
        ],
      ),
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GrowthRadii.icon),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GrowthSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(value,
                style: TextStyle(
                  color: GrowthColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                )),
            const SizedBox(width: GrowthSpacing.xs),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: GrowthColors.gray4),
          ],
        ),
      ),
    );
  }
}

/// 白纸预览页（v14：预览为白纸页面，不得出现深色头/灰底）
class ExportPreviewPage extends ConsumerStatefulWidget {
  const ExportPreviewPage({super.key});

  @override
  ConsumerState<ExportPreviewPage> createState() => _ExportPreviewPageState();
}

class _ExportPreviewPageState extends ConsumerState<ExportPreviewPage> {
  List<QuestionRecord> _questions = const [];
  PdfSettings _settings = const PdfSettings();
  bool _loading = true;
  bool _exporting = false;
  int _done = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exportCtx = ref.read(exportContextProvider);
    if (exportCtx == null) {
      if (mounted) context.pop();
      return;
    }
    _settings = exportCtx.settings;
    final db = ref.read(databaseProvider);
    final questions = <QuestionRecord>[];
    for (final id in exportCtx.ids) {
      final rows = await (db.select(db.questionRecords)
            ..where((t) => t.id.equals(id)))
          .get();
      if (rows.isNotEmpty) questions.add(rows.first);
    }
    if (mounted) {
      setState(() {
        _questions = questions;
        _loading = false;
      });
    }
  }

  Future<String?> _generateFile() async {
    final db = ref.read(databaseProvider);
    return QuestionPdfExporter.exportToFile(
      db,
      _questions,
      _settings,
      scanner: ref.read(scannerBridgeProvider),
      onProgress: (done, total) {
        if (mounted) {
          setState(() {
            _done = done;
            _total = total;
          });
        }
      },
    );
  }

  Future<void> _shareOrSave({required bool saveOnly}) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final path = await _generateFile();
      if (!mounted) return;
      if (path == null) {
        AppToast.error(context, '导出失败：没有可导出的题目');
        return;
      }
      if (saveOnly) {
        AppToast.success(context, '已保存：$path');
        return;
      }
      // 系统分享面板（含 Android 系统打印入口）
      await Printing.sharePdf(
        bytes: await File(path).readAsBytes(),
        filename: '错题导出.pdf',
      );
    } catch (e) {
      if (mounted) AppToast.error(context, '导出失败：$e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _print() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final db = ref.read(databaseProvider);
      final bytes = await QuestionPdfExporter.buildPdf(
        db,
        _questions,
        _settings,
        scanner: ref.read(scannerBridgeProvider),
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _done = done;
              _total = total;
            });
          }
        },
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '错题导出',
      );
    } catch (e) {
      if (mounted) AppToast.error(context, '打印失败：$e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 预览页恒定浅色白纸（深色例外）
      backgroundColor: const Color(0xFFEDEFF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEFF2),
        foregroundColor: GrowthColors.gray6,
        elevation: 0,
        title: Text(
          '预览（${_questions.length} 题）',
          style: TextStyle(color: GrowthColors.gray6, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(GrowthSpacing.md),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: GrowthSpacing.md),
                    itemBuilder: (context, i) => _PaperPage(
                      question: _questions[i],
                      index: i,
                      settings: _settings,
                      ref: ref,
                    ),
                  ),
                ),
                if (_exporting)
                  LinearProgressIndicator(
                    value: _total == 0 ? null : _done / _total,
                  ),
                // 出口：保存/分享/打印
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                    GrowthSpacing.lg,
                    GrowthSpacing.sm,
                    GrowthSpacing.lg,
                    MediaQuery.of(context).padding.bottom + GrowthSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GrowthButton(
                          label: '保存',
                          variant: GrowthButtonVariant.secondary,
                          loading: _exporting,
                          onPressed: () => _shareOrSave(saveOnly: true),
                        ),
                      ),
                      const SizedBox(width: GrowthSpacing.sm),
                      Expanded(
                        child: GrowthButton(
                          label: '分享',
                          variant: GrowthButtonVariant.secondary,
                          loading: _exporting,
                          onPressed: () => _shareOrSave(saveOnly: false),
                        ),
                      ),
                      const SizedBox(width: GrowthSpacing.sm),
                      Expanded(
                        child: GrowthButton(
                          label: '打印',
                          loading: _exporting,
                          onPressed: _print,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// 白纸页预览（与 PDF 内容一致的 Flutter 重建）
class _PaperPage extends StatelessWidget {
  const _PaperPage({
    required this.question,
    required this.index,
    required this.settings,
    required this.ref,
  });

  final QuestionRecord question;
  final int index;
  final PdfSettings settings;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final hasImage = q.imagePath != null && File(q.imagePath!).existsSync();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(GrowthSpacing.lg),
      child: FutureBuilder<String>(
        future: _breadcrumb(),
        builder: (context, crumb) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '第 ${index + 1} 题',
                  style: TextStyle(
                    fontSize: settings.fontSize + 2,
                    fontWeight: FontWeight.w700,
                    color: GrowthColors.gray6,
                  ),
                ),
                const SizedBox(width: GrowthSpacing.sm),
                Expanded(
                  child: Text(
                    crumb.data ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: settings.fontSize - 2,
                      color: GrowthColors.gray5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GrowthSpacing.sm),
            if (q.stem.isNotEmpty && !q.stem.startsWith('（图片题'))
              Padding(
                padding: const EdgeInsets.only(bottom: GrowthSpacing.sm),
                child: Text(
                  q.stem,
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    height: 1.5,
                    color: GrowthColors.gray6,
                  ),
                ),
              ),
            if (hasImage)
              Center(
                child: Image.file(
                  File(q.imagePath!),
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: GrowthSpacing.md),
            Text(
              '作答区',
              style: TextStyle(
                fontSize: settings.fontSize - 1,
                color: GrowthColors.gray4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GrowthSpacing.xs),
            for (var i = 0; i < 5; i++)
              Container(
                margin: const EdgeInsets.only(bottom: GrowthSpacing.lg),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFB8BCC6), width: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<String> _breadcrumb() async {
    final db = ref.read(databaseProvider);
    final links = await (db.select(db.questionKnowledgeLinks)
          ..where((t) => t.questionId.equals(question.id)))
        .get();
    if (links.isEmpty) return '';
    final kpIds = links.map((l) => l.knowledgePointId).toList();
    final kps = await (db.select(db.knowledgePoints)
          ..where((t) => t.id.isIn(kpIds)))
        .get();
    if (kps.isEmpty) return '';
    final kp = kps.first;
    return [kp.subject, kp.version, kp.book, kp.chapter, kp.lesson, kp.name]
        .where((s) => s.isNotEmpty)
        .join(' · ');
  }
}
