import 'package:dio/dio.dart';

import '../../core/ai/ai_call.dart';
import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_provider_config.dart';
import 'ai_provider_repository.dart';

/// AI 配置仓储（Prompt G）：
/// - 非敏感字段（名称/Base URL/模型）持久化到 Drift
/// - API Key 只进 flutter_secure_storage，严禁明文落库或打印日志
/// - 页面初始化从仓库 hydrate 回填
class AiConfigRepository {
  AiConfigRepository(this._repo);

  final AiProviderRepository _repo;

  /// hydrate：默认服务商配置 + 密钥（Key 仅内存持有，UI 层掩码展示）
  Future<({AiProviderConfig? config, String apiKey})> loadDraft() async {
    final config = await _repo.defaultProvider();
    if (config == null) return (config: null, apiKey: '');
    final vault = AiKeyVault();
    final key = await vault.read(config) ?? '';
    return (config: config, apiKey: key);
  }

  /// 保存配置 + 密钥，并设为默认
  Future<void> save({
    required String name,
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    final config = AiProviderConfig.create(
      name: name.trim().isEmpty ? '主力模型' : name.trim(),
      baseUrl: normalizeBaseUrl(baseUrl),
      model: model.trim(),
      isDefault: true,
    );
    await _repo.save(config: config, apiKey: apiKey.trim());
  }

  /// 获取模型列表：只校验 Base URL + API Key（模型字段不参与，解除死锁）
  Future<({List<String> models, String? error})> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    final url = normalizeBaseUrl(baseUrl);
    if (url.isEmpty || apiKey.trim().isEmpty) {
      return (models: const <String>[], error: '请先填写 Base URL 和 API Key');
    }
    final client = AiClient(
      config: AiProviderConfig.create(
        name: 'probe',
        baseUrl: url,
        model: 'probe',
      ),
      apiKey: apiKey.trim(),
    );
    try {
      final models = await AiCall.run(() => client.fetchModels());
      return (models: models, error: null);
    } on AiCallException catch (e) {
      return (models: const <String>[], error: e.userMessage);
    } on DioException catch (e) {
      return (models: const <String>[], error: classifyDioError(e));
    } catch (e) {
      return (models: const <String>[], error: '请求失败：$e');
    }
  }

  /// 测试连接：返回明确的成功/失败信息
  Future<({bool ok, String message})> testConnection({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    final url = normalizeBaseUrl(baseUrl);
    if (url.isEmpty || apiKey.trim().isEmpty || model.trim().isEmpty) {
      return (ok: false, message: '请先完整填写 Base URL、API Key 和模型');
    }
    final client = AiClient(
      config: AiProviderConfig.create(
        name: 'probe',
        baseUrl: url,
        model: model.trim(),
      ),
      apiKey: apiKey.trim(),
    );
    try {
      final ok = await AiCall.run(() => client.testConnectionOrThrow());
      return ok
          ? (ok: true, message: '连接成功，服务可用')
          : (ok: false, message: '服务返回异常：响应中没有可用结果');
    } on AiCallException catch (e) {
      return (ok: false, message: e.userMessage);
    } on DioException catch (e) {
      return (ok: false, message: classifyDioError(e));
    } catch (e) {
      return (ok: false, message: '连接失败：\$e');
    }
  }

  /// Base URL 规范化：自动补 https:// 前缀，去尾部斜杠
  static String normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url.replaceAll(RegExp(r'/+$'), '');
  }

  /// 错误分级：给用户看得懂的原因
  static String classifyDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '请求超时：检查地址是否可达';
      case DioExceptionType.connectionError:
        return '无法连接：地址无效或网络不可达';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          return '认证失败（$code）：请检查 API Key';
        }
        if (code == 404) {
          return '地址无效（404）：请检查 Base URL';
        }
        return '服务异常（$code）';
      default:
        return '请求失败：${e.message ?? '未知原因'}';
    }
  }
}
