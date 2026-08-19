import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'ai_message.dart';
import 'ai_provider_config.dart';

/// OpenAI 兼容客户端：统一服务错题解析 / 追问 / 举一反三 / MOSS 伴读。
///
/// 多模态（图片）消息在 P2 引入；P0 先落地文本对话 + 流式输出。
class AiClient {
  AiClient({
    required AiProviderConfig config,
    required String apiKey,
    Dio? dio,
    this.defaultTimeout = const Duration(seconds: 30),
  })  : _config = config,
        _apiKey = apiKey,
        _dio = dio ?? Dio();

  final AiProviderConfig _config;
  final String _apiKey;
  final Dio _dio;
  final Duration defaultTimeout;

  /// 只读配置访问（补钉 A：gateway 日志需要 model 名）
  AiProviderConfig get config => _config;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  /// 非流式对话
  Future<String> chat({
    required List<AiMessage> messages,
    String? model,
    double temperature = 0.3,
    int maxTokens = 2048,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      _config.chatCompletionsUrl,
      data: buildRequestBody(
        messages: messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        stream: false,
      ),
      options: Options(
        headers: _headers,
        sendTimeout: defaultTimeout,
        receiveTimeout: defaultTimeout,
      ),
    );
    final data = resp.data;
    if (data == null) throw const AiClientException('empty response');
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const AiClientException('no choices in response');
    }
    final message = choices.first as Map<String, dynamic>;
    final content = (message['message'] as Map<String, dynamic>?)?['content'];
    return content?.toString() ?? '';
  }

  /// 流式对话（SSE），逐段产出增量文本
  Stream<AiStreamChunk> chatStream({
    required List<AiMessage> messages,
    String? model,
    double temperature = 0.3,
    int maxTokens = 2048,
  }) async* {
    final resp = await _dio.post<ResponseBody>(
      _config.chatCompletionsUrl,
      data: buildRequestBody(
        messages: messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        stream: true,
      ),
      options: Options(
        headers: _headers,
        responseType: ResponseType.stream,
        sendTimeout: defaultTimeout,
        receiveTimeout: defaultTimeout,
      ),
    );
    final body = resp.data;
    if (body == null) throw const AiClientException('empty stream');

    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload == '[DONE]') {
        yield const AiStreamChunk(delta: '', finished: true);
        return;
      }
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) continue;
      final delta = (choices.first as Map<String, dynamic>)['delta']
          as Map<String, dynamic>?;
      final text = delta?['content']?.toString();
      if (text != null && text.isNotEmpty) {
        yield AiStreamChunk(delta: text);
      }
      final finishReason =
          (choices.first as Map<String, dynamic>)['finish_reason'];
      if (finishReason != null) {
        yield const AiStreamChunk(delta: '', finished: true);
        return;
      }
    }
  }

  /// 拉取可用模型列表（配置向导用）
  Future<List<String>> fetchModels() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      _config.modelsUrl,
      options: Options(
        headers: _headers,
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    final data = resp.data?['data'] as List<dynamic>? ?? const [];
    return data
        .map((e) => (e as Map<String, dynamic>)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();
  }

  /// 连接测试：一次最小对话。
  /// Part 0.2：失败时抛出真实 DioException，由上层分级提示，禁笼统"无法连接"。
  Future<bool> testConnectionOrThrow() async {
    final probe = AiProviderConfig.create(
      name: 'probe',
      baseUrl: _config.normalizedBaseUrl,
      model: _config.model,
    );
    final chatUrl = probe.chatCompletionsUrl;
    final resp = await _dio.post<Map<String, dynamic>>(
      chatUrl,
      data: {
        'model': _config.model,
        'messages': const [
          {'role': 'user', 'content': 'ping'}
        ],
        'max_tokens': 8,
      },
      options: Options(
        headers: _headers,
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final data = resp.data;
    return data != null &&
        (data['choices'] as List<dynamic>?)?.isNotEmpty == true;
  }

  /// 请求体构造（抽出来便于单测）
  Map<String, dynamic> buildRequestBody({
    required List<AiMessage> messages,
    String? model,
    double temperature = 0.3,
    int maxTokens = 2048,
    bool stream = false,
  }) =>
      {
        'model': model ?? _config.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (stream) 'stream': true,
      };
}

class AiClientException implements Exception {
  const AiClientException(this.message);
  final String message;
  @override
  String toString() => 'AiClientException: $message';
}
