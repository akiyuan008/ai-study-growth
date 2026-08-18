import 'dart:convert';

/// 练习来源等级（Part 3.4）
enum ExerciseSourceLevel {
  /// L1 个人真题库同知识点检索
  l1Personal('真题 · 来自你的题库'),

  /// L2 AI 真题引用（年份+地区+考卷名出处）
  l2Cited('真题引用'),

  /// L3 来源待核实（严禁编造出处）
  l3Unverified('来源待核实'),

  /// L4 AI 拟题
  l4Generated('AI 拟题');

  const ExerciseSourceLevel(this.defaultLabel);

  final String defaultLabel;
}

/// 举一反三练习题（单道，带来源标签）
class ExerciseItem {
  const ExerciseItem({
    required this.difficulty,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    this.sourceLevel = ExerciseSourceLevel.l4Generated,
    this.sourceLabel,
    this.bankId,
  });

  final String difficulty;
  final String question;
  final List<String> options;

  /// 正确选项字母，如 "A"
  final String answer;
  final String explanation;

  /// 来源等级与 UI 标签（每题必须可见）
  final ExerciseSourceLevel sourceLevel;
  final String? sourceLabel;

  /// L1 命中时关联的题库条目
  final String? bankId;

  String get displaySourceLabel => sourceLabel ?? sourceLevel.defaultLabel;

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty,
        'question': question,
        'options': options,
        'answer': answer,
        'explanation': explanation,
        'sourceLevel': sourceLevel.name,
        if (sourceLabel != null) 'sourceLabel': sourceLabel,
        if (bankId != null) 'bankId': bankId,
      };

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    // 内部格式：直接带 sourceLevel
    if (json['sourceLevel'] != null) {
      return ExerciseItem(
        difficulty: (json['difficulty'] ?? '').toString(),
        question: (json['question'] ?? '').toString(),
        options: (json['options'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        answer: (json['answer'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        sourceLevel: ExerciseSourceLevel.values.firstWhere(
          (l) => l.name == json['sourceLevel'],
          orElse: () => ExerciseSourceLevel.l4Generated,
        ),
        sourceLabel: json['sourceLabel']?.toString(),
        bankId: json['bankId']?.toString(),
      );
    }

    // AI 原始格式：sourceStatus + source → 映射到 L2/L3/L4
    final status = (json['sourceStatus'] ?? '').toString();
    final source = json['source'];
    ExerciseSourceLevel level;
    String? label;
    if (status == 'cited' && source is Map) {
      level = ExerciseSourceLevel.l2Cited;
      final year = (source['year'] ?? '').toString();
      final region = (source['region'] ?? '').toString();
      final exam = (source['examName'] ?? '').toString();
      label = '真题引用 · $year$region$exam';
    } else if (status == 'uncertain') {
      level = ExerciseSourceLevel.l3Unverified;
    } else {
      level = ExerciseSourceLevel.l4Generated;
    }

    return ExerciseItem(
      difficulty: (json['difficulty'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      options: (json['options'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      answer: (json['answer'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      sourceLevel: level,
      sourceLabel: label,
    );
  }
}

/// 解析「generatedExercises」AI 输出
List<ExerciseItem> parseExercises(String raw) {
  var text = raw.trim();
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
  final fm = fence.firstMatch(text);
  if (fm != null) text = fm.group(1)!.trim();

  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return const [];
  try {
    final decoded = jsonDecode(text.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) return const [];
    final list = decoded['generatedExercises'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ExerciseItem.fromJson(e))
        .where((e) => e.question.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
}
