import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:ai_study_growth/src/data/repositories/review_repository.dart';
import 'package:drift/drift.dart' hide Column, Table, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;
  final now = DateTime.now();
  const uuid = Uuid();

  Future<({String questionId, String cardId})> seedQuestionWithCard({
    DateTime? due,
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

  test('评分：FSRS 推进卡片、写日志、更新掌握度、发学习事件', () async {
    final seeded = await seedQuestionWithCard();

    await repo.rate(cardId: seeded.cardId, rating: Rating.easy, now: now);

    // 卡片：新卡评 easy → 进入复习态，due 推到未来
    final card = await (db.select(db.reviewCards)
          ..where((t) => t.id.equals(seeded.cardId)))
        .getSingle();
    expect(card.state, State.review.value);
    expect(card.stability, greaterThan(0));
    expect(card.reps, 1);
    expect(card.due.isAfter(now), isTrue);
    expect(card.lastReviewAt, isNotNull);

    // 日志
    final logs = await db.select(db.reviewLogs).get();
    expect(logs, hasLength(1));
    expect(logs.first.rating, Rating.easy.value);

    // 掌握度：review 态且 stability 刚起步 → 3（长期记忆）
    final question = await (db.select(db.questionRecords)
          ..where((t) => t.id.equals(seeded.questionId)))
        .getSingle();
    expect(question.masteryLevel, 3);

    // 学习事件
    final events = await db.select(db.learningEvents).get();
    expect(events.single.eventType, 'review_done');
    expect(events.single.questionId, seeded.questionId);

    // 评分后不再到期
    expect(await repo.dueCount(now: now), 0);
  });

  test('忘记（again）会让卡片当天内再次到期', () async {
    final seeded = await seedQuestionWithCard();
    await repo.rate(cardId: seeded.cardId, rating: Rating.again, now: now);

    final card = await (db.select(db.reviewCards)
          ..where((t) => t.id.equals(seeded.cardId)))
        .getSingle();
    // 学习态 again → 1 分钟后再现（Drift 按秒存储，容忍截断误差）
    expect(card.due.difference(now).inSeconds, closeTo(60, 1));
    expect(card.state, State.learning.value);
  });
}
