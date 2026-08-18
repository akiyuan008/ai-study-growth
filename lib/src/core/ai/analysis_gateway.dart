import 'dart:convert';
import 'dart:io';

import '../../domain/models/analysis_result.dart';
import '../../domain/models/generated_exercise.dart';
import 'ai_client.dart';
import 'ai_message.dart';
import 'prompts.dart';

/// AI 解析网关 —— 学习域与 AI 大脑之间的唯一接口。
///
/// 实现可替换：[AiAnalysisGatewayImpl]（真实）/ FakeGateway（测试）。
abstract interface class AiAnalysisGateway {
  /// 拆题：一张图中有几道独立题目
  Future<List<QuestionCandidate>> splitQuestions({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  });

  /// 单题解析：给图片（直接看图）或已确认题干文本
  Future<AnalysisResult> analyzeQuestion({
    List<int>? imageBytes,
    String mimeType = 'image/jpeg',
    String? questionText,
  });

  /// 举一反三
  Future<List<ExerciseItem>> generateExercises({
    required String stem,
    required String answer,
    required List<String> steps,
    required String mistakeReason,
    required List<String> knowledgePoints,
  });

  /// 追问答疑（流式）
  Stream<String> followUp({
    required String questionContext,
    required List<AiMessage> history,
    required String question,
  });

  /// MOSS 伴读通用对话（流式，无题目上下文）
  Stream<String> companionChat({
    required List<AiMessage> history,
    required String message,
  });

  /// 知识点分类（Part 3.1）：AI 仅输出结构化知识点标签列表。
  /// 严禁生成题干/答案/错因等解析内容。
  Future<List<String>> suggestKnowledgeTags({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  });
}

class AiAnalysisGatewayImpl implements AiAnalysisGateway {
  AiAnalysisGatewayImpl(this._client);

  final AiClient _client;

  @override
  Future<List<QuestionCandidate>> splitQuestions({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final raw = await _client.chat(
      messages: [
        const AiMessage(role: 'system', content: AiPrompts.splitSystem),
        userMessageWithImage(
          text: '请拆分这张图片中的题目。',
          imageBytes: imageBytes,
          mimeType: mimeType,
        ),
      ],
      temperature: 0.1,
      maxTokens: 4096,
    );
    final json = extractJsonObject(raw);
    final list = json?['questions'];
    if (list is! List || list.isEmpty) {
      throw const AiGatewayException('拆题失败：无法识别图片中的题目');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => QuestionCandidate.fromJson(e))
        .toList();
  }

  @override
  Future<AnalysisResult> analyzeQuestion({
    List<int>? imageBytes,
    String mimeType = 'image/jpeg',
    String? questionText,
  }) async {
    final hasText = questionText != null && questionText.trim().isNotEmpty;
    final userMsg = hasText
        ? AiMessage(
            role: 'user',
            content: '已确认的题目文本如下，请分析：\n$questionText',
          )
        : userMessageWithImage(
            text: '请分析图片中的这道题。',
            imageBytes: imageBytes ?? const [],
            mimeType: mimeType,
          );

    final raw = await _client.chat(
      messages: [
        const AiMessage(role: 'system', content: AiPrompts.analysisSystem),
        userMsg,
      ],
      temperature: 0.2,
      maxTokens: 4096,
    );
    final json = extractJsonObject(raw);
    if (json == null) {
      throw const AiGatewayException('解析失败：AI 返回内容无法识别');
    }
    return AnalysisResult.fromJson(json);
  }

  @override
  Future<List<ExerciseItem>> generateExercises({
    required String stem,
    required String answer,
    required List<String> steps,
    required String mistakeReason,
    required List<String> knowledgePoints,
  }) async {
    final context = AiPrompts.followUpContext(
      stem: stem,
      answer: answer,
      steps: steps,
      mistakeReason: mistakeReason,
      knowledgePoints: knowledgePoints,
    );
    final raw = await _client.chat(
      messages: [
        const AiMessage(role: 'system', content: AiPrompts.exerciseSystem),
        AiMessage(role: 'user', content: '请基于以下错题生成举一反三练习：\n$context'),
      ],
      temperature: 0.5,
      maxTokens: 4096,
    );
    return parseExercises(raw);
  }

  @override
  Future<List<String>> suggestKnowledgeTags({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    const system = '你是一个知识点分类器。只看题目图片，输出该题涉及的知识点标签。'
        '规则：只输出 JSON 数组（如 ["高中物理","力学","牛顿第二定律"]），3-6 个，'
        '从学科大类到具体知识点递进；不解题、不写答案、不输出任何其他文字。';
    final raw = await _client.chat(
      messages: [
        const AiMessage(role: 'system', content: system),
        userMessageWithImage(
          text: '请输出知识点标签。',
          imageBytes: imageBytes,
          mimeType: mimeType,
        ),
      ],
      temperature: 0.1,
      maxTokens: 256,
    );
    final json = extractJsonObject(raw) ?? _tryParseArray(raw);
    if (json == null) return const [];
    final list = json['tags'];
    if (list is List) {
      return list.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static Map<String, dynamic>? _tryParseArray(String raw) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start < 0 || end <= start) return null;
    try {
      final arr = jsonDecode(raw.substring(start, end + 1));
      if (arr is List) return {'tags': arr};
    } catch (_) {}
    return null;
  }

  @override
  Stream<String> companionChat({
    required List<AiMessage> history,
    required String message,
  }) async* {
    final messages = [
      const AiMessage(
        role: 'system',
        content: '你是 MOSS，一个温和的数字伴读。用引导式、启发式的语气陪用户聊天：'
            '聊学习状态、给节奏建议、帮忙拆解拖延。回答简短（2-4 句），不说教。',
      ),
      ...history,
      AiMessage(role: 'user', content: message),
    ];
    await for (final chunk in _client.chatStream(
      messages: messages,
      temperature: 0.6,
      maxTokens: 512,
    )) {
      if (chunk.delta.isNotEmpty) yield chunk.delta;
    }
  }

  @override
  Stream<String> followUp({
    required String questionContext,
    required List<AiMessage> history,
    required String question,
  }) async* {
    final messages = [
      const AiMessage(role: 'system', content: AiPrompts.followUpSystem),
      AiMessage(role: 'system', content: questionContext),
      ...history,
      AiMessage(role: 'user', content: question),
    ];
    await for (final chunk in _client.chatStream(
      messages: messages,
      temperature: 0.4,
      maxTokens: 2048,
    )) {
      if (chunk.delta.isNotEmpty) yield chunk.delta;
    }
  }
}

/// 从文件路径读图片字节（管线与文件系统解耦的注入点）
typedef ImageBytesLoader = Future<List<int>> Function(String path);

Future<List<int>> defaultImageBytesLoader(String path) =>
    File(path).readAsBytes();

class AiGatewayException implements Exception {
  const AiGatewayException(this.message);
  final String message;
  @override
  String toString() => 'AiGatewayException: $message';
}
