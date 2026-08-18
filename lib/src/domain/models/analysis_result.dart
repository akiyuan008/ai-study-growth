import 'dart:convert';

import 'subject.dart';

/// AI 解析结果（单道题）。
///
/// 从 awn 移植并精简：保留学习闭环必需字段，
/// 视觉假设/一致性校验等重型机制留待后续阶段。
class AnalysisResult {
  const AnalysisResult({
    required this.subject,
    required this.stem,
    required this.finalAnswer,
    required this.steps,
    required this.tags,
    required this.knowledgePoints,
    required this.mistakeReason,
    this.studyAdvice = '',
  });

  final Subject subject;

  /// 整理后的完整题干
  final String stem;
  final String finalAnswer;
  final List<String> steps;

  /// AI 短标签（2-4 个，每个 2-8 字）
  final List<String> tags;

  /// 知识点详述
  final List<String> knowledgePoints;
  final String mistakeReason;
  final String studyAdvice;

  /// 容错解析：AI 输出可能带 markdown 围栏或前后缀噪声
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) => (v is List)
        ? v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    return AnalysisResult(
      subject: Subject.fromName(json['subject']?.toString()),
      stem:
          (json['reconstructedQuestionText'] ?? json['stem'] ?? '').toString(),
      finalAnswer: (json['finalAnswer'] ?? '').toString(),
      steps: strList(json['steps']),
      tags: strList(json['aiTags'] ?? json['tags']),
      knowledgePoints: strList(json['knowledgePoints']),
      mistakeReason: (json['mistakeReason'] ?? '').toString(),
      studyAdvice: (json['studyAdvice'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject.name,
        'reconstructedQuestionText': stem,
        'finalAnswer': finalAnswer,
        'steps': steps,
        'aiTags': tags,
        'knowledgePoints': knowledgePoints,
        'mistakeReason': mistakeReason,
        'studyAdvice': studyAdvice,
      };

  String encode() => jsonEncode(toJson());

  factory AnalysisResult.decode(String raw) =>
      AnalysisResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// 从 AI 原始文本中提取 JSON 对象（剥掉围栏与噪声）
Map<String, dynamic>? extractJsonObject(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;

  // 剥 markdown 围栏
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
  final fm = fence.firstMatch(text);
  if (fm != null) text = fm.group(1)!.trim();

  // 定位第一个 { 到最后一个 }
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  final candidate = text.substring(start, end + 1);

  try {
    final decoded = jsonDecode(candidate);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    // 常见修复：去除尾逗号
    try {
      final repaired = candidate.replaceAllMapped(
        RegExp(r',\s*([}\]])'),
        (m) => m.group(1)!,
      );
      final decoded = jsonDecode(repaired);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return null;
}

/// 拆题结果：一张图中的候选题目
class QuestionCandidate {
  const QuestionCandidate({required this.index, required this.text});

  final int index;
  final String text;

  Map<String, dynamic> toJson() => {'index': index, 'text': text};

  factory QuestionCandidate.fromJson(Map<String, dynamic> json) =>
      QuestionCandidate(
        index: (json['index'] as num?)?.toInt() ?? 0,
        text: (json['text'] ?? '').toString(),
      );
}

/// 逐题解析状态
enum CandidateStatus { pending, analyzing, success, failed }

class CandidateAnalysis {
  const CandidateAnalysis({
    required this.index,
    required this.status,
    this.result,
    this.error,
  });

  final int index;
  final CandidateStatus status;
  final AnalysisResult? result;
  final String? error;

  CandidateAnalysis copyWith({
    CandidateStatus? status,
    AnalysisResult? result,
    String? error,
  }) =>
      CandidateAnalysis(
        index: index,
        status: status ?? this.status,
        result: result ?? this.result,
        error: error,
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'status': status.name,
        if (result != null) 'result': result!.toJson(),
        if (error != null) 'error': error,
      };

  factory CandidateAnalysis.fromJson(Map<String, dynamic> json) {
    final resultJson = json['result'];
    return CandidateAnalysis(
      index: (json['index'] as num?)?.toInt() ?? 0,
      status: CandidateStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CandidateStatus.pending,
      ),
      result: resultJson is Map<String, dynamic>
          ? AnalysisResult.fromJson(resultJson)
          : null,
      error: json['error']?.toString(),
    );
  }
}
