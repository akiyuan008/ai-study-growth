import 'dart:convert';

/// 举一反三练习题（单道）
class ExerciseItem {
  const ExerciseItem({
    required this.difficulty,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final String difficulty;
  final String question;
  final List<String> options;

  /// 正确选项字母，如 "A"
  final String answer;
  final String explanation;

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty,
        'question': question,
        'options': options,
        'answer': answer,
        'explanation': explanation,
      };

  factory ExerciseItem.fromJson(Map<String, dynamic> json) => ExerciseItem(
        difficulty: (json['difficulty'] ?? '').toString(),
        question: (json['question'] ?? '').toString(),
        options: (json['options'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        answer: (json['answer'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
      );
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
