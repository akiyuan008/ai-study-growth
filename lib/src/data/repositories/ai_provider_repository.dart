import 'package:drift/drift.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_provider_config.dart';
import '../local/app_database.dart';

/// AI 服务商配置仓库：Drift 存配置，SecureStorage 存密钥。
class AiProviderRepository {
  AiProviderRepository(this._db, [AiKeyVault? vault])
      : _vault = vault ?? const AiKeyVault();

  final AppDatabase _db;
  final AiKeyVault _vault;

  Future<List<AiProviderConfig>> list() async {
    final rows = await (_db.select(_db.aiProviders)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toConfig).toList();
  }

  Future<AiProviderConfig?> defaultProvider() async {
    final rows = await (_db.select(_db.aiProviders)
          ..where((t) => t.isDefault.equals(true))
          ..limit(1))
        .get();
    if (rows.isEmpty) return null;
    return _toConfig(rows.first);
  }

  /// 保存配置 + 密钥。apiKey 只进 secure storage。
  Future<AiProviderConfig> save({
    required AiProviderConfig config,
    required String apiKey,
  }) async {
    await _db.into(_db.aiProviders).insertOnConflictUpdate(
          AiProvidersCompanion.insert(
            id: config.id,
            name: config.name,
            baseUrl: config.normalizedBaseUrl,
            model: config.model,
            keyRef: config.keyRef,
            isDefault: Value(config.isDefault),
            createdAt: config.createdAt,
          ),
        );
    await _vault.store(config, apiKey);
    if (config.isDefault) {
      await _clearOtherDefaults(config.id);
    }
    return config;
  }

  Future<void> setDefault(String id) async {
    await _clearOtherDefaults(id);
    await (_db.update(_db.aiProviders)..where((t) => t.id.equals(id)))
        .write(const AiProvidersCompanion(isDefault: Value(true)));
  }

  Future<void> delete(String id) async {
    final rows = await (_db.select(_db.aiProviders)
          ..where((t) => t.id.equals(id)))
        .get();
    for (final row in rows) {
      await _vault.delete(_toConfig(row));
    }
    await (_db.delete(_db.aiProviders)..where((t) => t.id.equals(id))).go();
  }

  /// 读取密钥并构造可用客户端（P2 起由 AI 大脑统一调用）
  Future<AiClient?> buildClient(String id) async {
    final rows = await (_db.select(_db.aiProviders)
          ..where((t) => t.id.equals(id)))
        .get();
    if (rows.isEmpty) return null;
    final config = _toConfig(rows.first);
    final key = await _vault.read(config);
    if (key == null || key.isEmpty) return null;
    return AiClient(config: config, apiKey: key);
  }

  Future<void> _clearOtherDefaults(String exceptId) async {
    await (_db.update(_db.aiProviders)
          ..where((t) => t.id.equals(exceptId).not()))
        .write(const AiProvidersCompanion(isDefault: Value(false)));
  }

  AiProviderConfig _toConfig(AiProvider row) => AiProviderConfig(
        id: row.id,
        name: row.name,
        baseUrl: row.baseUrl,
        model: row.model,
        keyRef: row.keyRef,
        isDefault: row.isDefault,
        createdAt: row.createdAt,
      );
}
