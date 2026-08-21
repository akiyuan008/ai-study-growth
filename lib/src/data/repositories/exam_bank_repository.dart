import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 内置真题（GAOKAO-Bench 真实高考题）
class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.subject,
    required this.year,
    required this.exam,
    required this.stem,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final String id;
  final String subject;
  final String year;
  final String exam;
  final String stem;
  final List<String> options;
  final String answer;
  final String explanation;

  /// 展示用出处：如「真题 · 2019 新课标」
  String get sourceLabel =>
      '真题 · $year${exam.isNotEmpty ? ' $exam' : ''}';
}

/// 内置真题库仓储（assets 懒加载 + 内存缓存）。
///
/// 数据源：GAOKAO-Bench（OpenLMLab）2010-2022 真实高考客观题。
/// 举一反三优先从这里出题（真题），AI 拟题仅作补充。
abstract final class ExamBankRepository {
  static List<ExamQuestion>? _cache;

  static Future<List<ExamQuestion>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/exam_bank/exam_bank.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['questions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((q) => ExamQuestion(
                id: (q['id'] ?? '').toString(),
                subject: (q['subject'] ?? '').toString(),
                year: (q['year'] ?? '').toString(),
                exam: (q['exam'] ?? '').toString(),
                stem: (q['stem'] ?? '').toString(),
                options: (q['options'] as List? ?? const [])
                    .map((e) => e.toString())
                    .toList(),
                answer: (q['answer'] ?? '').toString(),
                explanation: (q['explanation'] ?? '').toString(),
              ))
          .toList();
      _cache = list;
      return list;
    } catch (_) {
      _cache = const [];
      return const [];
    }
  }

  /// 按科目 + 关键词检索真题（排除指定题干，随机打散后取 limit 条）。
  /// keywords 用于粗匹配知识点（题干含任一关键词优先）。
  static Future<List<ExamQuestion>> search({
    required String subject,
    List<String> keywords = const [],
    String excludeStem = '',
    int limit = 2,
  }) async {
    final all = await _load();
    final pool = all
        .where((q) => q.subject == subject)
        .where((q) => q.stem.trim() != excludeStem.trim())
        .toList();
    if (pool.isEmpty) return const [];

    // 关键词命中优先，其次随机
    final kw = keywords
        .map((k) => k.trim())
        .where((k) => k.length >= 2)
        .toList();
    int score(ExamQuestion q) {
      var s = 0;
      for (final k in kw) {
        if (q.stem.contains(k)) s += 2;
        if (q.explanation.contains(k)) s += 1;
      }
      return s;
    }

    pool.shuffle();
    pool.sort((a, b) => score(b).compareTo(score(a)));
    return pool.take(limit).toList();
  }

  /// 题库规模（设置页展示）
  static Future<int> count() async => (await _load()).length;

  /// 覆盖科目
  static Future<List<String>> subjects() async {
    final all = await _load();
    return all.map((q) => q.subject).toSet().toList();
  }
}
