import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0 验收：Drift 数据库初始化无报错，全部核心表可读写。
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
    expect(await db.select(db.focusSessions).get(), isEmpty);
    expect(await db.select(db.focusEvents).get(), isEmpty);
    expect(await db.select(db.missions).get(), isEmpty);
    expect(await db.select(db.learningEvents).get(), isEmpty);
    expect(await db.select(db.growthMetrics).get(), isEmpty);
    expect(await db.select(db.aiProviders).get(), isEmpty);
    expect(await db.select(db.analysisJobs).get(), isEmpty);
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

  test('自律域：任务 + 专注会话 + 行为事件流', () async {
    final now = DateTime.now();
    await db.into(db.missions).insert(
          MissionsCompanion.insert(
            id: 'm-1',
            title: '今日到期复习',
            source: const Value('review_engine'),
            scheduledFor: '2026-08-18',
            requirement: const Value('{"type":"review_due","count":8}'),
            createdAt: now,
          ),
        );
    await db.into(db.focusSessions).insert(
          FocusSessionsCompanion.insert(
            id: 'fs-1',
            missionId: const Value('m-1'),
            questionIds: const Value('["q-1"]'),
            mode: const Value('abyss'),
            startedAt: now,
            plannedMs: const Value(25 * 60 * 1000),
          ),
        );
    await db.into(db.focusEvents).insert(
          FocusEventsCompanion.insert(
            sessionId: const Value('fs-1'),
            eventType: 'app_usage',
            appPackage: const Value('com.example.video'),
            at: now,
            durationMs: const Value(65000),
          ),
        );

    final session = await db.select(db.focusSessions).getSingle();
    expect(session.mode, 'abyss');
    expect(session.status, 'active');
    expect(session.focusMs, 0); // 真实专注时长由 focusMath 事后计算
  });

  test('成长引擎：事件流 + 每日快照', () async {
    final now = DateTime.now();
    await db.into(db.learningEvents).insert(
          LearningEventsCompanion.insert(
            eventType: 'review_done',
            questionId: const Value('q-1'),
            at: now,
            payload: const Value('{"rating":3}'),
          ),
        );
    await db.into(db.growthMetrics).insert(
          GrowthMetricsCompanion.insert(
            date: '2026-08-18',
            learningScore: const Value(62.5),
            focusScore: const Value(71.0),
            persistenceScore: const Value(55.0),
            recoveryScore: const Value(48.0),
            focusMs: const Value(50 * 60 * 1000),
            streak: const Value(3),
          ),
        );

    final snapshot = await db.select(db.growthMetrics).getSingle();
    expect(snapshot.learningScore, closeTo(62.5, 0.001));
    expect(snapshot.focusScore, closeTo(71.0, 0.001));
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
}
