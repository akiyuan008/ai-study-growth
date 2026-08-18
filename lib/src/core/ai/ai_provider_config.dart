import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// AI 服务商配置。
///
/// 安全约定：apiKey 永不写入 Drift/日志，只经 [AiKeyVault] 存进
/// flutter_secure_storage；配置对象里只保留 [keyRef]（保险库键名）。
class AiProviderConfig {
  AiProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    required this.keyRef,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;

  /// OpenAI 兼容 Base URL，如 https://api.openai.com/v1
  final String baseUrl;
  final String model;

  /// secure storage 中存放 apiKey 的键名
  final String keyRef;
  final bool isDefault;
  final DateTime createdAt;

  factory AiProviderConfig.create({
    required String name,
    required String baseUrl,
    required String model,
    bool isDefault = false,
  }) {
    final id = _uuid.v4();
    return AiProviderConfig(
      id: id,
      name: name,
      baseUrl: baseUrl,
      model: model,
      keyRef: 'ai_provider_key_$id',
      isDefault: isDefault,
    );
  }

  /// 规范化 Base URL：去尾部斜杠
  String get normalizedBaseUrl => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  String get chatCompletionsUrl => '$normalizedBaseUrl/chat/completions';
  String get modelsUrl => '$normalizedBaseUrl/models';

  AiProviderConfig copyWith({
    String? name,
    String? baseUrl,
    String? model,
    bool? isDefault,
  }) =>
      AiProviderConfig(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        keyRef: keyRef,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt,
      );
}

/// apiKey 保险箱：flutter_secure_storage 的薄封装
class AiKeyVault {
  const AiKeyVault([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<void> store(AiProviderConfig config, String apiKey) =>
      _storage.write(key: config.keyRef, value: apiKey);

  Future<String?> read(AiProviderConfig config) =>
      _storage.read(key: config.keyRef);

  Future<void> delete(AiProviderConfig config) =>
      _storage.delete(key: config.keyRef);
}
