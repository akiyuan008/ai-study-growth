import 'package:ai_study_growth/src/core/ai/ai_provider_config.dart';
import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:ai_study_growth/src/data/repositories/ai_provider_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试替身：密钥存内存，不走平台通道
class _MemoryVault extends AiKeyVault {
  final Map<String, String> keys = {};

  @override
  Future<void> store(AiProviderConfig config, String apiKey) async {
    keys[config.keyRef] = apiKey;
  }

  @override
  Future<String?> read(AiProviderConfig config) async => keys[config.keyRef];

  @override
  Future<void> delete(AiProviderConfig config) async {
    keys.remove(config.keyRef);
  }
}

void main() {
  late AppDatabase db;
  late _MemoryVault vault;
  late AiProviderRepository repo;

  setUp(() {
    db = openAppDatabaseMemory();
    vault = _MemoryVault();
    repo = AiProviderRepository(db, vault);
  });

  tearDown(() async {
    await db.close();
  });

  test('保存配置：密钥只进保险箱，数据库只留 keyRef', () async {
    final config = AiProviderConfig.create(
      name: '主力',
      baseUrl: 'https://api.example.com/v1',
      model: 'gpt-4o',
      isDefault: true,
    );
    await repo.save(config: config, apiKey: 'sk-secret');

    final rows = await db.select(db.aiProviders).get();
    expect(rows, hasLength(1));
    // 数据库任何字段都不含明文密钥
    expect(rows.first.toString(), isNot(contains('sk-secret')));
    expect(vault.keys[config.keyRef], 'sk-secret');

    final loaded = await repo.defaultProvider();
    expect(loaded, isNotNull);
    expect(loaded!.model, 'gpt-4o');
  });

  test('setDefault 互斥：只有一个默认服务商', () async {
    final a = AiProviderConfig.create(
      name: 'A',
      baseUrl: 'https://a.com/v1',
      model: 'm1',
      isDefault: true,
    );
    final b = AiProviderConfig.create(
      name: 'B',
      baseUrl: 'https://b.com/v1',
      model: 'm2',
    );
    await repo.save(config: a, apiKey: 'k1');
    await repo.save(config: b, apiKey: 'k2');
    await repo.setDefault(b.id);

    final defaults = await (db.select(db.aiProviders)
          ..where((t) => t.isDefault.equals(true)))
        .get();
    expect(defaults, hasLength(1));
    expect(defaults.first.id, b.id);
  });

  test('删除配置同时清理保险箱密钥', () async {
    final c = AiProviderConfig.create(
      name: 'C',
      baseUrl: 'https://c.com/v1',
      model: 'm3',
    );
    await repo.save(config: c, apiKey: 'k3');
    expect(vault.keys, contains(c.keyRef));

    await repo.delete(c.id);
    expect(await repo.list(), isEmpty);
    expect(vault.keys, isNot(contains(c.keyRef)));
  });
}
