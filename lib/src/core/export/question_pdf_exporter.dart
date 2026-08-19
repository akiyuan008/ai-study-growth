import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/local/app_database.dart';

/// 题目 PDF 导出（Part 6.2）：离线生成，每题一页（原图+面包屑+作答空白区）。
/// 支持存本地 / 分享 / Android 系统打印。
abstract final class QuestionPdfExporter {
  /// 生成 PDF 文件，返回本地路径
  static Future<String> export(
    AppDatabase db,
    List<QuestionRecord> questions,
  ) async {
    final doc = pw.Document();

    for (final (i, q) in questions.indexed) {
      final breadcrumb = await _breadcrumbOf(db, q.id);
      final image = await _loadImage(q.imagePath);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 页眉：序号 + 面包屑
              pw.Row(
                children: [
                  pw.Text(
                    '第 ${i + 1} 题',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Text(
                      breadcrumb.isEmpty ? '未分类' : breadcrumb,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              // 题干文字（如有）
              if (q.stem.isNotEmpty && !q.stem.startsWith('（图片题'))
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text(
                    q.stem,
                    style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
                  ),
                ),
              // 原图
              if (image != null)
                pw.Center(
                  child: pw.SizedBox(
                    height: 340,
                    child: pw.Image(
                      image,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              pw.Spacer(),
              // 作答空白区（横线）
              pw.Text(
                '作答区',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              for (var line = 0; line < 6; line++)
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 26),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'))
      ..createSync(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(exportDir.path, '错题导出_$stamp.pdf'));
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  /// 分享/打印：调用系统分享面板（Android 打印在分享面板内）
  static Future<void> share(String path) async {
    await Printing.sharePdf(
      bytes: await File(path).readAsBytes(),
      filename: p.basename(path),
    );
  }

  static Future<pw.MemoryImage?> _loadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return pw.MemoryImage(await file.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  static Future<String> _breadcrumbOf(AppDatabase db, String qid) async {
    final links = await (db.select(db.questionKnowledgeLinks)
          ..where((t) => t.questionId.equals(qid)))
        .get();
    if (links.isEmpty) return '';
    final kpIds = links.map((l) => l.knowledgePointId).toList();
    final kps = await (db.select(db.knowledgePoints)
          ..where((t) => t.id.isIn(kpIds)))
        .get();
    if (kps.isEmpty) return '';
    final kp = kps.first;
    final parts = [
      kp.subject,
      kp.version,
      kp.book,
      kp.chapter,
      kp.lesson,
      kp.name,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(' · ');
  }
}
