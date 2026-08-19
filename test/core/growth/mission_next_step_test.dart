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

  group('NextStepEngine 规则优先级', () {
    test('有到期复习 → 复习优先', () async {
      await seedDueCard(await seedQuestion());
      final step = await NextStepEngine.suggest(db, at: now);
      expect(step.route, '/review');
    });

    test('无到期复习且 3 天无新题 → 建议拍题', () async {
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
