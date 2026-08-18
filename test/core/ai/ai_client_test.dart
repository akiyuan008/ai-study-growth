import 'package:ai_study_growth/src/core/ai/ai_client.dart';
import 'package:ai_study_growth/src/core/ai/ai_message.dart';
import 'package:ai_study_growth/src/core/ai/ai_provider_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AiProviderConfig config;
  late AiClient client;

  setUp(() {
    config = AiProviderConfig(
      id: 'p-1',
      name: 'test',
      baseUrl: 'https://api.example.com/v1/',
      model: 'test-model',
      keyRef: 'ai_provider_key_p-1',
    );
    client = AiClient(config: config, apiKey: 'sk-test');
  });

  group('AiProviderConfig', () {
    test('baseUrl 规范化：去尾部斜杠', () {
      expect(config.normalizedBaseUrl, 'https://api.example.com/v1');
      expect(config.chatCompletionsUrl,
          'https://api.example.com/v1/chat/completions');
      expect(config.modelsUrl, 'https://api.example.com/v1/models');
    });

    test('create 工厂自动生成 id 与 keyRef', () {
      final c = AiProviderConfig.create(
        name: 'x',
        baseUrl: 'https://a.com/v1',
        model: 'm',
      );
      expect(c.id, isNotEmpty);
      expect(c.keyRef, 'ai_provider_key_${c.id}');
    });
  });

  group('AiClient.buildRequestBody', () {
    test('默认使用配置中的模型，消息序列化正确', () {
      final body = client.buildRequestBody(
        messages: const [
          AiMessage(role: 'system', content: '你是数字伴读'),
          AiMessage(role: 'user', content: '这道题为什么错？'),
        ],
      );
      expect(body['model'], 'test-model');
      expect(body['stream'], isNull);
      final messages = body['messages'] as List<dynamic>;
      expect(messages, hasLength(2));
      expect((messages[0] as Map<String, dynamic>)['role'], 'system');
    });

    test('流式请求携带 stream 标记，可覆盖模型', () {
      final body = client.buildRequestBody(
        messages: const [AiMessage(role: 'user', content: 'hi')],
        model: 'other-model',
        stream: true,
      );
      expect(body['stream'], true);
      expect(body['model'], 'other-model');
    });
  });
}
