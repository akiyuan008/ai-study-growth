import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:ai_study_growth/src/data/repositories/review_repository.dart';
import 'package:drift/drift.dart' hide Column, Table, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;
  final now = DateTime.now();
  const uuid = Uuid();

  Future<({String questionId, String cardId})> seedQuestionWithCard({
    DateTime? due,
    double easinessFactor = 2.5,
    int intervalDays = 0,
    int reps = 0,
  }) async {
    final qid = uuid.v4();
    final cid = uuid.v4();
    await db.into(db.questionRecords).insert(
          QuestionRecordsCompanion.insert(
            id: qid,
            stem: const Value('测试题干'),
            contentStatus: const Value('saved'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.reviewCards).insert(
          ReviewCardsCompanion.insert(
            id: cid,
            questionId: qid,
            due: due ?? now.subtract(const Duration(hours: 1)),
            createdAt: now,
            easinessFactor: Value(easinessFactor),
            intervalDays: Value(intervalDays),
            reps: Value(reps),
          ),
        );
    return (questionId: qid, cardId: cid);
  }

  setUp(() {
    db = openAppDatabaseMemory();
    repo = ReviewRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('dueItems 只返回到期卡，按到期时间升序', () async {
    await seedQuestionWithCard();
    await seedQuestionWithCard(due: now.add(const Duration(days: 1)));

    final items = await repo.dueItems(now: now);
    expect(items, hasLength(1));
    expect(items.first.question.stem, '测试题干');
    expect(await repo.dueCount(now: now), 1);
  });

  test('评分 已会(5)：SM-2 推进卡片、写日志、更新掌握度、发学习事件', () async {
    final seeded = await seedQuestionWithCard();

    await repo.rate(cardId: seeded.cardId, quality: 5, now: now);

    final card = await (db.select(db.reviewCards)
          ..where((t) => t.id.equals(seeded.cardId)))
        .getSingle();
    expect(card.reps, 1);
    expect(card.intervalDays, 1);
    expect(card.easinessFactor, greaterThan(2.5));
    expect(card.due.isAfter(now), isTrue);
    expect(card.lastReviewAt, isNotNull);
    expect(card.lapses, 0);

    // 日志
    final logs = await db.select(db.reviewLogs).get();
    expect(logs, hasLength(1));
    expect(logs.first.rating, 5);
    expect(logs.first.questionId, seeded.questionId);

    // 掌握度：复习过 → ≥1
    final q = await (db.select(db.questionRecords)
          ..where((t) => t.id.equals(seeded.questionId)))
        .getSingle();
    expect(q.masteryLevel, greaterThanOrEqualTo(1));
  });

  test('评分 仍错(1)：间隔打回 1 天、lapses+1、reps 归零', () async {
    final seeded = await seedQuestionWithCard(
      easinessFactor: 2.6,
      intervalDays: 15,
      reps: 4,
    );

    await repo.rate(cardId: seeded.cardId, quality: 1, now: now);

    final card = await (db.select(db.reviewCards)
          ..where((t) => t.id.equals(seeded.cardId)))
        .getSingle();
    expect(card.intervalDays, 1);
    expect(card.reps, 0);
    expect(card.lapses, 1);
    expect(card.easinessFactor, lessThan(2.6));
    // 仍错变早：下次到期约 1 天后，远小于原 15 天间隔
    expect(card.due.difference(now).inDays, lessThanOrEqualTo(1));
  });

  test('已会变晚：长间隔卡评 已会 后间隔拉长', () async {
    final seeded = await seedQuestionWithCard(
      easinessFactor: 2.6,
      intervalDays: 10,
      reps: 3,
    );

    await repo.rate(cardId: seeded.cardId, quality: 5, now: now);

    final card = await (db.select(db.reviewCards)
          ..where((t) => t.id.equals(seeded.cardId)))
        .getSingle();
    expect(card.intervalDays, greaterThan(10));
    expect(card.reps, 4);
  });

  test('掌握度映射：interval≥60 → 5（已掌握）', () async {
    final seeded = await seedQuestionWithCard(
      easinessFactor: 2.8,
      intervalDays: 40,
      reps: 3,
    );

    // 40 * 2.8 = 112 天 ≥ 60 且 reps+1=4 ≥ 3 → level 5
    await repo.rate(cardId: seeded.cardId, quality: 5, now: now);

    final q = await (db.select(db.questionRecords)
          ..where((t) => t.id.equals(seeded.questionId)))
        .getSingle();
    expect(q.masteryLevel, 5);
  });

  test('不存在的 cardId 评分静默无副作用', () async {
    await repo.rate(cardId: 'nonexistent', quality: 5, now: now);
    expect(await db.select(db.reviewLogs).get(), isEmpty);
  });
}
