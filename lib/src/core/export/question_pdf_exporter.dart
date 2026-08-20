import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/local/app_database.dart';
import '../bridge/scanner_bridge.dart';

/// PDF 打印设置（v14：字号/图片内容/含举一反三）
class PdfSettings {
  const PdfSettings({
    this.largeFont = false,
    this.useEnhanced = true,
    this.includeExercises = false,
  });

  /// 字号：标准(12)/大号(15)
  final bool largeFont;

  /// 图片内容：增强图/原图
  final bool useEnhanced;

  /// 附举一反三同类题
  final bool includeExercises;

  double get fontSize => largeFont ? 15 : 12;
}

/// 题目 PDF 导出（v14 重做）：
/// - 嵌中文字体（霞鹜文屏 Lite，开源 OFL），豆腐块清零
/// - 页面用增强图（可选原图）；白纸页面
/// - 含举一反三开关（附同类题）
abstract final class QuestionPdfExporter {
  static pw.Font? _fontCache;

  static Future<pw.Font> _loadFont() async {
    if (_fontCache != null) return _fontCache!;
    final data = await rootBundle.load('assets/fonts/LxgwWenKaiLite.ttf');
    _fontCache = pw.Font.ttf(data);
    return _fontCache!;
  }

  /// 生成 PDF 字节
  static Future<Uint8List> buildPdf(
    AppDatabase db,
    List<QuestionRecord> questions,
    PdfSettings settings, {
    ScannerBridge? scanner,
    void Function(int done, int total)? onProgress,
  }) async {
    final font = await _loadFont();
    final doc = pw.Document();
    final fs = settings.fontSize;

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final breadcrumb = await _breadcrumbOf(db, q.id);
      final imageBytes = await _imageBytes(q, settings, scanner);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(base: font),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 页眉：序号 + 面包屑
              pw.Row(
                children: [
                  pw.Text(
                    '第 ${i + 1} 题',
                    style: pw.TextStyle(
                      fontSize: fs + 2,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Text(
                      breadcrumb.isEmpty ? '未分类' : breadcrumb,
                      style: pw.TextStyle(
                        fontSize: fs - 2,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              // 题干文字（若有真实填写）
              if (q.stem.isNotEmpty && !q.stem.startsWith('（图片题'))
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text(
                    q.stem,
                    style: pw.TextStyle(fontSize: fs, lineSpacing: 4),
                  ),
                ),
              // 题目图片（图即题干）
              if (imageBytes != null)
                pw.SizedBox(
                  height: 340,
                  child: pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(imageBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              pw.Spacer(),
              // 作答空白区（横线）
              pw.Text(
                '作答区',
                style: pw.TextStyle(
                  fontSize: fs - 1,
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
                      bottom:
                          pw.BorderSide(color: PdfColors.grey400, width: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      // 举一反三附页
      if (settings.includeExercises) {
        final exercises = await _exercisesOf(db, q.id);
        if (exercises.isNotEmpty) {
          doc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(36),
              theme: pw.ThemeData.withFont(base: font),
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '第 ${i + 1} 题 · 举一反三',
                    style: pw.TextStyle(
                      fontSize: fs + 2,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  for (final (j, ex) in exercises.indexed) ...[
                    pw.Text(
                      '${j + 1}. ${ex['question']}',
                      style: pw.TextStyle(fontSize: fs, lineSpacing: 3),
                    ),
                    pw.SizedBox(height: 4),
                    for (final opt in (ex['options'] as List))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16),
                        child: pw.Text('$opt',
                            style: pw.TextStyle(fontSize: fs - 1)),
                      ),
                    pw.SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          );
        }
      }
      onProgress?.call(i + 1, questions.length);
    }

    return doc.save();
  }

  /// 生成并落盘，返回本地路径
  static Future<String> exportToFile(
    AppDatabase db,
    List<QuestionRecord> questions,
    PdfSettings settings, {
    ScannerBridge? scanner,
    void Function(int done, int total)? onProgress,
  }) async {
    final bytes = await buildPdf(db, questions, settings,
        scanner: scanner, onProgress: onProgress);
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'))
      ..createSync(recursive: true);
    final file = File(p.join(
        exportDir.path, '错题导出_${DateTime.now().millisecondsSinceEpoch}.pdf'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// 取题目图片字节（增强图优先，失败回落原图）
  static Future<Uint8List?> _imageBytes(
    QuestionRecord q,
    PdfSettings settings,
    ScannerBridge? scanner,
  ) async {
    if (q.imagePath == null) return null;
    var path = q.imagePath!;
    if (settings.useEnhanced && scanner != null) {
      final enhanced = await scanner.enhance(path);
      if (enhanced != null) path = enhanced;
    }
    final file = File(path);
    if (!file.existsSync()) {
      // 增强路径无效回落原图
      final fallback = File(q.imagePath!);
      if (!fallback.existsSync()) return null;
      return fallback.readAsBytes();
    }
    return file.readAsBytes();
  }

  /// 题目关联的同类练习题（题库飞轮，按知识点检索）
  static Future<List<Map<String, dynamic>>> _exercisesOf(
    AppDatabase db,
    String questionId,
  ) async {
    final links = await (db.select(db.questionKnowledgeLinks)
          ..where((t) => t.questionId.equals(questionId)))
        .get();
    if (links.isEmpty) return const [];
    final kpIds = links.map((l) => l.knowledgePointId).toList();
    final banks = await (db.select(db.questionBank)
          ..where((t) => t.knowledgePointId.isIn(kpIds))
          ..orderBy([(t) => OrderingTerm.asc(t.usedCount)])
          ..limit(3))
        .get();
    final result = <Map<String, dynamic>>[];
    for (final b in banks) {
      try {
        final content = Map<String, dynamic>.from(jsonDecode(b.content) as Map);
        if ((content['question'] ?? '').toString().isNotEmpty) {
          result.add(content);
        }
      } catch (_) {}
    }
    return result;
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
    return [kp.subject, kp.version, kp.book, kp.chapter, kp.lesson, kp.name]
        .where((s) => s.isNotEmpty)
        .join(' · ');
  }
}
