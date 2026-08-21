import 'dart:convert';
import 'dart:io';

import 'ai_call.dart';
import 'json_extract.dart';
import '../../domain/models/generated_exercise.dart';
import '../../domain/models/knowledge_path.dart';
import 'ai_client.dart';
import 'ai_message.dart';
import 'prompts.dart';

/// AI 解析网关 —— 学习域与 AI 大脑之间的唯一接口。
///
/// 实现可替换：[AiAnalysisGatewayImpl]（真实）/ FakeGateway（测试）。
abstract interface class AiAnalysisGateway {
  /// v15 终版：AI 举一反三 —— 调用必出≥1 题
  /// 解析放宽（多种结构）→ 格式强化重试一次 → 仍失败将 AI 原文作为练习卡（标"AI 拟题"）
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

  /// v15 终版：AI 举一反三 —— 必出≥1 题
  /// 第一轮：正常解析（宽松）
  /// 第二轮：格式强化重试一次
  /// 兜底：仍失败将 AI 原文作为练习卡，标"AI 拟题"
  Future<List<ExerciseItem>> generateExercises({
    required String stem,
    required String answer,
    required List<String> steps,
    required String mistakeReason,
    required List<String> knowledgePoints,
  }) async {
    // ---- 第一轮：正常解析（宽松） ----
    final context = AiPrompts.followUpContext(
      stem: stem,
      answer: answer,
      steps: steps,
      mistakeReason: mistakeReason,
      knowledgePoints: knowledgePoints,
    );

    try {
      final raw = await _chatWithLog(
        purpose: 'exercise',
        messages: [
          const AiMessage(role: 'system', content: AiPrompts.exerciseSystem),
          AiMessage(role: 'user', content: '请基于以下错题生成举一反三练习：\n$context'),
        ],
        temperature: 0.5,
        maxTokens: 4096,
      );
      final items = parseExercises(raw);
      if (items.isNotEmpty) return items;
    } catch (_) {}

    // ---- 第二轮：格式强化重试 ----
    try {
      final retryRaw = await _chatWithLog(
        purpose: 'exercise_retry',
        messages: [
          const AiMessage(
            role: 'system',
            content: AiPrompts.exerciseSystemStrict,
          ),
          AiMessage(
            role: 'user',
            content: '请严格按 JSON 格式输出至少一道练习题：\n$context',
          ),
        ],
        temperature: 0.3,
        maxTokens: 4096,
      );
      final retryItems = parseExercises(retryRaw);
      if (retryItems.isNotEmpty) return retryItems;
    } catch (_) {}

    // ---- 兜底：将 AI 原文作为练习卡（标"AI 拟题"） ----
    // 尝试获取原始响应文本作为兜底
    try {
      final fallbackRaw = await _chatWithLog(
        purpose: 'exercise_fallback',
        messages: [
          const AiMessage(
            role: 'system',
            content: '你是一个高中教师。请直接给出一道与原题同知识点的练习题，包含题目、选项、答案和简要解析。',
          ),
          AiMessage(
            role: 'user',
            content: '原题：$stem\n答案：$answer\n请出一道同类练习题。',
          ),
        ],
        temperature: 0.7,
        maxTokens: 2048,
      );
      // 将 AI 原文包装为 ExerciseItem，标来源为 L4(AI 拟题)
      return [
        ExerciseItem(
          question: fallbackRaw.trim(),
          options: const [],
          answer: '',
          explanation: 'AI 拟题（原文输出）',
          difficulty: 'AI 拟题',
          sourceLevel: ExerciseSourceLevel.l4Generated,
          bankId: null,
        ),
      ];
    } catch (e) {
      // 最终兜底：返回一个空壳提示用户
      return [
        ExerciseItem(
          question: 'AI 生成暂时不可用，请稍后重试或手动添加同类题。',
          options: const [],
          answer: '',
          explanation: e.toString(),
          difficulty: '暂无',
          sourceLevel: ExerciseSourceLevel.l4Generated,
          bankId: null,
        ),
      ];
    }
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
        'book(册别，如必修第一册)、chapter(章)、lesson(节)、point(知识点名称)。'
        '不确定的层级留空字符串。示例：'
        '{"subject":"物理","version":"人教版2019","book":"必修第一册","chapter":"第三章 相互作用","lesson":"第3节 牛顿第三定律","point":"牛顿第三定律"}';
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
