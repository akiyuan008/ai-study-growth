import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/local/app_database.dart';
import '../bridge/scanner_bridge.dart';

/// PDF 打印设置（v15 终版：字号/图片内容/答案开关/答案位置/多选）
class PdfSettings {
  const PdfSettings({
    this.largeFont = false,
    this.useEnhanced = true,
    this.includeExercises = false,
    this.includeAnswers = true,
    this.answersAtEnd = false,
  });

  /// 字号：标准(12)/大号(15)
  final bool largeFont;

  /// 图片内容：增强图/原图
  final bool useEnhanced;

  /// 附举一反三同类题
  final bool includeExercises;

  /// 是否包含答案
  final bool includeAnswers;

  /// 答案位置：false=题后 / true=统一最后
  final bool answersAtEnd;

  double get fontSize => largeFont ? 15 : 12;
}

/// 题目 PDF 导出（v15 终版）：
/// - 嵌中文字体（霞鹜文屏 Lite，开源 OFL），豆腐块清零
/// - 页面用增强图（可选原图）；白纸页面
/// - 多选支持（可勾选同类题一并导出）
/// - 答案开关 + 答案位置（题后/统一最后）
/// - 保存/分享/系统打印
abstract final class QuestionPdfExporter {
  /// 导出 PDF 到文件（保存/分享用）
  static Future<String?> exportToFile(
    AppDatabase db,
    List<QuestionRecord> questions,
    PdfSettings settings, {
    ScannerBridge? scanner,
    void Function(int done, int total)? onProgress,
  }) async {
    if (questions.isEmpty) return null;
    final bytes = await buildPdf(
      db,
      questions,
      settings,
      scanner: scanner,
      onProgress: onProgress,
    );
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, '错题导出_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await File(path).writeAsBytes(bytes);
    return path;
  }

  static pw.Font? _fontCache;

  static Future<pw.Font> _loadFont() async {
    if (_fontCache != null) return _fontCache!;
    final data = await rootBundle.load('assets/fonts/LxgwWenKaiLite.ttf');
    _fontCache = pw.Font.ttf(data);
    return _fontCache!;
  }

  /// 生成 PDF 字节（多选模式）
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

    // 收集所有题目页面和答案页（如果 answersAtEnd）
    final answerPages = <pw.Widget>[];

    for (var i = 0; i < questions.length; i++) {
      onProgress?.call(i + 1, questions.length);

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

              // 题目图片（v15：大图展示，禁止占位文案）
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

              // 题干文字（仅在有真实填写时显示）
              if (q.stem.isNotEmpty && !q.stem.startsWith('（图片题'))
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text(
                    q.stem,
                    style: pw.TextStyle(fontSize: fs, lineSpacing: 4),
                  ),
                ),

              // 答案（题后模式）
              if (settings.includeAnswers && !settings.answersAtEnd)
                _buildAnswerSection(q, fs),

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

      // 收集答案页（统一最后模式）
      if (settings.includeAnswers && settings.answersAtEnd) {
        answerPages.add(pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '第 ${i + 1} 题答案',
              style: pw.TextStyle(fontSize: fs, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if ((q.answer ?? '').isNotEmpty)
              pw.Text(q.answer!, style: pw.TextStyle(fontSize: fs)),
            if ((q.errorCause ?? '').isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  '错因：${q.errorCause}',
                  style: pw.TextStyle(fontSize: fs - 1, color: PdfColors.grey600),
                ),
              ),
          ],
        ));
      }

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
                      fontSize: fs + 1,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  for (final ex in exercises.take(3)) ...[
                    pw.Text(
                      (ex['question'] ?? '').toString(),
                      style: pw.TextStyle(fontSize: fs, lineSpacing: 3),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '答案：${ex['answer'] ?? ''}',
                      style: pw.TextStyle(
                        fontSize: fs - 1,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          );
        }
      }
    }

    // 统一最后：追加答案汇总页
    if (settings.includeAnswers && settings.answersAtEnd && answerPages.isNotEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(base: font),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '答案汇总',
                style: pw.TextStyle(
                  fontSize: fs + 2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              ...answerPages,
            ],
          ),
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _buildAnswerSection(QuestionRecord q, double fs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Text(
          '答案',
          style: pw.TextStyle(
            fontSize: fs - 1,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        if ((q.answer ?? '').isNotEmpty)
          pw.Text(q.answer!, style: pw.TextStyle(fontSize: fs)),
        if ((q.errorCause ?? '').isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '错因：${q.errorCause}',
              style: pw.TextStyle(fontSize: fs - 1, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  static Future<String> _breadcrumbOf(AppDatabase db, String qid) async {
    final links = await (db.select(db.questionKnowledgeLinks)
          ..where((t) => t.questionId.equals(qid)))
        .get();
    if (links.isEmpty) return '';
    final kpIds = links.map((l) => l.knowledgePointId).toSet().toList();
    final kps = await (db.select(db.knowledgePoints)
          ..where((t) => t.id.isIn(kpIds)))
        .get();
    final segs = kps.map((k) {
      final parts = [k.subject, k.chapter, k.name]
          .where((s) => s.isNotEmpty)
          .toList();
      return parts.join(' · ');
    }).toList();
    return segs.join('；');
  }

  static Future<Uint8List?> _imageBytes(
    QuestionRecord q,
    PdfSettings settings,
    ScannerBridge? scanner,
  ) async {
    final path = q.imagePath;
    if (path == null || !File(path).existsSync()) return null;
    // 如果要求增强图且增强引擎可用，返回增强后的路径
    if (settings.useEnhanced && scanner != null) {
      try {
        final enhanced = await scanner.enhance(path);
        if (enhanced != null && File(enhanced).existsSync()) {
          return await File(enhanced).readAsBytes();
        }
      } catch (_) {}
    }
    return File(path).readAsBytes();
  }

  static Future<List<Map<String, dynamic>>> _exercisesOf(
      AppDatabase db, String qid) async {
    final rows = await (db.select(db.generatedExercises)
          ..where((t) => t.questionId.equals(qid)))
        .get();
    final result = <Map<String, dynamic>>[];
    for (final r in rows) {
      try {
        final content = jsonDecode(r.content) as Map<String, dynamic>;
        result.add({
          'question': content['question'] as String? ?? '',
          'answer': content['answer'] as String? ?? '',
          'explanation': content['explanation'] as String? ?? '',
        });
      } catch (_) {
        // content 不是预期格式的 JSON，跳过
      }
    }
    return result;
  }
}
