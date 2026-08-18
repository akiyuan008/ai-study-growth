import 'package:ai_study_growth/src/core/growth/mission_engine.dart';
import 'package:ai_study_growth/src/core/growth/next_step.dart';
import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:drift/drift.dart' hide Column, Table, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 8, 18, 10);

  Future<String> seedQuestion() async {
    final id = _uuid.v4();
    await db.into(db.questionRecords).insert(
          QuestionRecordsCompanion.insert(
            id: id,
            stem: const Value('题干'),
            contentStatus: const Value('saved'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> seedDueCard(String questionId) async {
    await db.into(db.reviewCards).insert(
          ReviewCardsCompanion.insert(
            id: _uuid.v4(),
            questionId: questionId,
            due: now.subtract(const Duration(hours: 1)),
            createdAt: now,
          ),
        );
  }

  Future<void> seedReviewEvent({DateTime? at}) async {
    await db.into(db.learningEvents).insert(
          LearningEventsCompanion.insert(
            eventType: 'review_done',
            questionId: Value(await seedQuestion()),
            at: at ?? now,
          ),
        );
  }

  setUp(() {
    db = openAppDatabaseMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('MissionEngine 复习即任务', () {
    test('有到期复习时自动生成当日任务', () async {
      await seedDueCard(await seedQuestion());
      await seedDueCard(await seedQuestion());

      final created = await MissionEngine.generateDailyMissions(db, now: now);
      expect(created, hasLength(1));

      final missions = await MissionEngine.todayMissions(db, at: now);
      expect(missions, hasLength(1));
      expect(missions.first.source, 'review_engine');
      expect(missions.first.title, contains('2 道'));
    });

    test('幂等：同一天重复生成不会重复建', () async {
      await seedDueCard(await seedQuestion());
      await MissionEngine.generateDailyMissions(db, now: now);
      await MissionEngine.generateDailyMissions(db, now: now);
      final missions = await MissionEngine.todayMissions(db, at: now);
      expect(missions, hasLength(1));
    });

    test('无到期复习不生成任务', () async {
      final created = await MissionEngine.generateDailyMissions(db, now: now);
      expect(created, isEmpty);
    });

    test('复习事件达标后任务自动完成', () async {
      await seedDueCard(await seedQuestion());
      await MissionEngine.generateDailyMissions(db, now: now);

      // 完成 1 次复习
      await seedReviewEvent();
      final completed = await MissionEngine.evaluateMissions(db, at: now);
      expect(completed, 1);

      final missions = await MissionEngine.todayMissions(db, at: now);
      expect(missions.first.status, 'done');
      expect(missions.first.completedAt, isNotNull);

      // 完成事件入成长事件流
      final events = await db.select(db.learningEvents).get();
      expect(events.map((e) => e.eventType), contains('mission_done'));
    });

    test('复习未达标时任务保持 active', () async {
      await seedDueCard(await seedQuestion());
      await seedDueCard(await seedQuestion());
      await MissionEngine.generateDailyMissions(db, now: now);

      await seedReviewEvent(); // 只完成 1/2
      await MissionEngine.evaluateMissions(db, at: now);

      final missions = await MissionEngine.todayMissions(db, at: now);
      expect(missions.first.status, 'active');
    });
  });

  group('NextStepEngine 规则优先级', () {
    test('有到期复习 → 复习优先', () async {
      await seedDueCard(await seedQuestion());
      final step = await NextStepEngine.suggest(db, at: now);
      expect(step.route, '/review');
    });

    test('无到期复习且今日未专注 → 建议专注', () async {
      final step = await NextStepEngine.suggest(db, at: now);
      expect(step.route, '/focus');
    });

    test('已专注足够但 3 天无新题 → 建议拍题', () async {
      await db.into(db.focusSessions).insert(
            FocusSessionsCompanion.insert(
              id: _uuid.v4(),
              startedAt: now.subtract(const Duration(hours: 1)),
              endedAt: Value(now),
              status: const Value('completed'),
              focusMs: const Value(30 * 60 * 1000),
            ),
          );
      final step = await NextStepEngine.suggest(db, at: now);
      expect(step.route, '/capture');
    });

    test('一切都在轨道上 → 保持节奏', () async {
      await db.into(db.focusSessions).insert(
            FocusSessionsCompanion.insert(
              id: _uuid.v4(),
              startedAt: now.subtract(const Duration(hours: 1)),
              endedAt: Value(now),
              status: const Value('completed'),
              focusMs: const Value(30 * 60 * 1000),
            ),
          );
      await db.into(db.questionRecords).insert(
            QuestionRecordsCompanion.insert(
              id: _uuid.v4(),
              stem: const Value('新题'),
              createdAt: now.subtract(const Duration(days: 1)),
              updatedAt: now,
            ),
          );
      final step = await NextStepEngine.suggest(db, at: now);
      expect(step.route, '/notebook');
    });
  });

  group('GrowthMemoryFeed', () {
    test('聚合双域事件并按时间倒序', () async {
      await seedReviewEvent(at: now.subtract(const Duration(minutes: 5)));
      await db.into(db.focusSessions).insert(
            FocusSessionsCompanion.insert(
              id: _uuid.v4(),
              startedAt: now.subtract(const Duration(hours: 2)),
              endedAt: Value(now.subtract(const Duration(hours: 1))),
              status: const Value('completed'),
              focusMs: const Value(50 * 60 * 1000),
            ),
          );

      final moments = await GrowthMemoryFeed.recent(db, at: now);
      expect(moments.length, greaterThanOrEqualTo(2));
      expect(
          moments.first.at.isAfter(moments.last.at) ||
              moments.first.at.isAtSameMomentAs(moments.last.at),
          isTrue);
      expect(moments.map((m) => m.kind), contains('focus'));
    });
  });
}
