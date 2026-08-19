import 'dart:convert';
import 'dart:io';

import '../../domain/models/analysis_result.dart';
import 'ai_call.dart';
import '../../domain/models/generated_exercise.dart';
import '../../domain/models/knowledge_path.dart';
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

  /// 知识点分类（Part 3.1）：AI 仅输出结构化知识点标签列表。
  /// 严禁生成题干/答案/错因等解析内容。
  Future<List<String>> suggestKnowledgeTags({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  });

  /// 层级知识点路径（Part 3.2 硬门 3）：
  /// AI 输出完整层级 {subject,version,book,chapter,lesson,point}。
  /// 视觉不支持时抛 AiCallException(visionUnsupported)，由 UI 守卫转手动。
  Future<KnowledgePath> suggestKnowledgePath({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  });
}

/// AI 调用日志回调（补钉 A）：每次 AI 调用后触发，由上层写入 AiCallLog 表。
typedef AiCallLogger = Future<void> Function({
  required String purpose,
  required String requestBody,
  required String responseBody,
  required int httpStatus,
  required bool success,
  String? errorTier,
  required int durationMs,
});

class AiAnalysisGatewayImpl implements AiAnalysisGateway {
  AiAnalysisGatewayImpl(this._client, {this.logger});

  final AiClient _client;

  /// 可选日志回调，非 null 时每次调用后写日志
  final AiCallLogger? logger;

  Future<String> _chatWithLog({
    required String purpose,
    required List<AiMessage> messages,
    double temperature = 0.3,
    int maxTokens = 2048,
  }) async {
    final sw = Stopwatch()..start();
    final reqBody = jsonEncode({
      'model': _client.config.model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
    });
    try {
      final raw = await AiCall.run(() => _client.chat(
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
          ));
      sw.stop();
      if (logger != null) {
        await logger!(
          purpose: purpose,
          requestBody: reqBody,
          responseBody: raw,
          httpStatus: 200,
          success: true,
          durationMs: sw.elapsedMilliseconds,
        );
      }
      return raw;
    } catch (e) {
      sw.stop();
      String? tier;
      if (e is AiCallException) tier = e.tier.name;
      if (logger != null) {
        await logger!(
          purpose: purpose,
          requestBody: reqBody,
          responseBody: e.toString(),
          httpStatus: e is AiCallException ? 500 : 0,
          success: false,
          errorTier: tier,
          durationMs: sw.elapsedMilliseconds,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<QuestionCandidate>> splitQuestions({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final raw = await _chatWithLog(
      purpose: 'split',
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

    final raw = await _chatWithLog(
      purpose: 'analyze',
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
    final raw = await _chatWithLog(
      purpose: 'exercise',
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
    final raw = await _chatWithLog(
      purpose: 'classify',
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
    if (json == null) {
      throw const AiCallException(AiErrorTier.parseFailed, detail: '未识别到标签结构');
    }
    final list = json['tags'];
    if (list is List) {
      return list.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  @override
  Future<KnowledgePath> suggestKnowledgePath({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    const system = '你是教材知识点分类器。只看题目图片，输出该题知识点在教材中的层级路径。'
        '规则：只输出 JSON，不要解题。字段：subject(学科)、version(教材版本，如人教版，可合理推断)、'
        'book(册别，如八年级上册)、chapter(章)、lesson(节)、point(知识点名称)。'
        '不确定的层级留空字符串。示例：'
        '{"subject":"物理","version":"人教版","book":"八年级下册","chapter":"第九章 压强","lesson":"第1节 压强","point":"压强"}';
    final raw = await _chatWithLog(
      purpose: 'classify',
      messages: [
        const AiMessage(role: 'system', content: system),
        userMessageWithImage(
          text: '请输出知识点层级路径。',
          imageBytes: imageBytes,
          mimeType: mimeType,
        ),
      ],
      temperature: 0.1,
      maxTokens: 300,
    );
    // JSON 提取 + 正则兜底
    var json = extractJsonObject(raw);
    if (json == null) {
      final m = RegExp(r'\{[^{}]*"point"[^{}]*\}').firstMatch(raw);
      if (m != null) {
        try {
          json = jsonDecode(m.group(0)!) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
    if (json == null) {
      throw const AiCallException(AiErrorTier.parseFailed, detail: '未识别到层级路径');
    }
    return KnowledgePath.fromJson(json);
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
