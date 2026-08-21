import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0 验收：Drift 数据库初始化无报错，全部核心表可读写。
/// v13：专注/任务/监控表已删除，新增 AiCallLogs 表
void main() {
  late AppDatabase db;

  setUp(() {
    db = openAppDatabaseMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test('schema 初始化：全部核心表存在且可查询', () async {
    expect(await db.select(db.questionRecords).get(), isEmpty);
    expect(await db.select(db.knowledgePoints).get(), isEmpty);
    expect(await db.select(db.questionKnowledgeLinks).get(), isEmpty);
    expect(await db.select(db.reviewCards).get(), isEmpty);
    expect(await db.select(db.reviewLogs).get(), isEmpty);
    expect(await db.select(db.generatedExercises).get(), isEmpty);
    expect(await db.select(db.aiMessages).get(), isEmpty);
    expect(await db.select(db.aiProviders).get(), isEmpty);
    expect(await db.select(db.analysisJobs).get(), isEmpty);
    expect(await db.select(db.aiCallLogs).get(), isEmpty);
  });

  test('学习域：题目 → 知识点 → 复习卡 → 复习日志 写入链路', () async {
    final now = DateTime.now();
    await db.into(db.questionRecords).insert(
          QuestionRecordsCompanion.insert(
            id: 'q-1',
            stem: const Value('一个物体从高处自由下落…'),
            subject: const Value('物理'),
            errorCause: const Value('未考虑空气阻力'),
            tags: const Value('["力学","自由落体"]'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.knowledgePoints).insert(
          KnowledgePointsCompanion.insert(
            id: 'kp-1',
            name: '自由落体',
            subject: const Value('物理'),
            firstSeenAt: now,
          ),
        );
    await db.into(db.questionKnowledgeLinks).insert(
          QuestionKnowledgeLinksCompanion.insert(
            questionId: 'q-1',
            knowledgePointId: 'kp-1',
          ),
        );
    await db.into(db.reviewCards).insert(
          ReviewCardsCompanion.insert(
            id: 'rc-1',
            questionId: 'q-1',
            due: now.add(const Duration(days: 1)),
            createdAt: now,
          ),
        );
    await db.into(db.reviewLogs).insert(
          ReviewLogsCompanion.insert(
            questionId: 'q-1',
            rating: 3,
            reviewedAt: now,
          ),
        );

    final q = await (db.select(db.questionRecords)
          ..where((t) => t.id.equals('q-1')))
        .getSingle();
    expect(q.stem, contains('自由下落'));
    expect(q.masteryLevel, 0);

    final links = await db.select(db.questionKnowledgeLinks).get();
    expect(links, hasLength(1));
  });

  test('AI 配置表：密钥不落库，只存 keyRef', () async {
    final now = DateTime.now();
    await db.into(db.aiProviders).insert(
          AiProvidersCompanion.insert(
            id: 'p-1',
            name: '主力模型',
            baseUrl: 'https://api.example.com/v1',
            model: 'gpt-4o',
            keyRef: 'ai_provider_key_p-1',
            isDefault: const Value(true),
            createdAt: now,
          ),
        );
    final row = await db.select(db.aiProviders).getSingle();
    expect(row.keyRef, 'ai_provider_key_p-1');
    expect(row.isDefault, isTrue);
  });

  test('AiCallLogs：写入与查询', () async {
    final now = DateTime.now();
    await db.into(db.aiCallLogs).insert(
          AiCallLogsCompanion.insert(
            purpose: 'classify',
            requestBody: '{"model":"gpt-4o"}',
            responseBody: '{"subject":"物理"}',
            httpStatus: const Value(200),
            success: const Value(true),
            durationMs: const Value(1500),
            at: now,
          ),
        );
    final logs = await db.select(db.aiCallLogs).get();
    expect(logs, hasLength(1));
    expect(logs.first.purpose, 'classify');
    expect(logs.first.success, isTrue);
    expect(logs.first.httpStatus, 200);
  });
}
