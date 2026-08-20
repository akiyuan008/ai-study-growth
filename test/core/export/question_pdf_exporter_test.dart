import 'package:ai_study_growth/src/core/export/question_pdf_exporter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('中文字体可嵌入 PDF（豆腐块清零验收）', () async {
    // 加载内置霞鹜文屏字体
    final data = await rootBundle.load('assets/fonts/LxgwWenKaiLite.ttf');
    expect(data.lengthInBytes, greaterThan(1024 * 1024),
        reason: '字体文件应完整下载（>1MB）');

    final font = pw.Font.ttf(data);

    // 用中文字符生成一页 PDF，验证不抛异常且字节非空
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('第 1 题',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('物理 · 人教版 · 必修第二册 · 第五章 抛体运动',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('作答区：一个物体做平抛运动，初速度为 v₀…',
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
    final bytes = await doc.save();
    expect(bytes.length, greaterThan(10 * 1024),
        reason: 'PDF 字节应包含嵌入字体子集（>10KB）');

    // PDF 头校验
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('PdfSettings 字号映射', () {
    expect(const PdfSettings().fontSize, 12);
    expect(const PdfSettings(largeFont: true).fontSize, 15);
    expect(const PdfSettings().useEnhanced, isTrue);
  });
}
