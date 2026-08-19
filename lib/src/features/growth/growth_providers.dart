import 'dart:convert';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/growth/growth_engine.dart';
import '../../core/growth/next_step.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/ai_provider_repository.dart';
import '../../data/services/ai_learning_services.dart';
import '../../design_system/growth_theme.dart' show sharedPreferencesProvider;

/// 成长趋势（近 7 日三能力快照）
class GrowthTrendPoint {
  const GrowthTrendPoint({
    required this.date,
    required this.learning,
    required this.persistence,
    required this.recovery,
  });

  final String date;
  final double learning;
  final double persistence;
  final double recovery;

  double get overall => (learning + persistence + recovery) / 3;
}

final growthTrendProvider =
    FutureProvider.autoDispose<List<GrowthTrendPoint>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await (db.select(db.growthMetrics)
        ..orderBy([(t) => OrderingTerm.desc(t.date)])
        ..limit(7))
      .get();
  return rows.reversed
      .map((r) => GrowthTrendPoint(
            date: r.date,
            learning: r.learningScore,
            persistence: r.persistenceScore,
            recovery: r.recoveryScore,
          ))
      .toList();
});

/// 成长首页的全部数据（内容契约：身份/三环/趋势/成长记忆/NextStep 链接）
class GrowthHomeData {
  const GrowthHomeData({
    required this.scores,
    required this.hasAnyActivity,
    required this.identity,
    required this.strongest,
    required this.streak,
    required this.nextStep,
    required this.moments,
    required this.dueReviewCount,
    required this.reviewCompletedToday,
    required this.reviewDueTotal,
    required this.newQuestionsToday,
  });

  final GrowthScores scores;
  final bool hasAnyActivity;
  final String identity;
  final String strongest;
  final int streak;
  final NextStep nextStep;
  final List<GrowthMoment> moments;

  final int dueReviewCount;
  final int reviewCompletedToday;
  final int reviewDueTotal;
  final int newQuestionsToday;

  String get reviewStatusLabel {
    if (reviewDueTotal == 0) return '暂无复习安排';
    if (reviewCompletedToday >= reviewDueTotal) return '复习已清空';
    return '$dueReviewCount 道题待复习';
  }
}

/// 成长首页数据聚合：聚合事实 → 计算三能力 → 快照落库 → NextStep
final growthHomeProvider =
    FutureProvider.autoDispose<GrowthHomeData>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  // 1) 连续天数
  final streak = await _computeStreak(db, now);

  // 2) 当日事实聚合
  final reviewEvents = await (db.select(db.learningEvents)
        ..where((t) =>
            t.eventType.equals('review_done') &
            t.at.isBiggerOrEqualValue(dayStart) &
            t.at.isSmallerThanValue(dayEnd)))
      .get();
  final dueCards = await (db.select(db.reviewCards)
        ..where((t) => t.due.isSmallerOrEqualValue(now)))
      .get();
  final newQuestions = await (db.select(db.questionRecords)
        ..where((t) =>
            t.createdAt.isBiggerOrEqualValue(dayStart) &
            t.createdAt.isSmallerThanValue(dayEnd)))
      .get();
  final exercisesToday = await (db.select(db.generatedExercises)
        ..where((t) =>
            t.createdAt.isBiggerOrEqualValue(dayStart) &
            t.createdAt.isSmallerThanValue(dayEnd)))
      .get();

  // 掌握度提升：复习后进入 review 态
  var masteryGains = 0;
  for (final e in reviewEvents) {
    try {
      final payload = jsonDecode(e.payload) as Map<String, dynamic>;
      if (payload['state'] == 'review') masteryGains++;
    } catch (_) {}
  }

  // 遗忘与错后重做正确（恢复能力输入）
  final reviewLogs = await (db.select(db.reviewLogs)
        ..where((t) => t.reviewedAt.isBiggerOrEqualValue(dayStart))
        ..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)]))
      .get();
  final lapsedQuestions = <String>{};
  var lapses = 0;
  var lapseRecoveries = 0;
  for (final log in reviewLogs) {
    if (log.rating == 1) {
      lapses++;
      lapsedQuestions.add(log.questionId);
    } else if (log.rating >= 3 && lapsedQuestions.contains(log.questionId)) {
      lapseRecoveries++;
      lapsedQuestions.remove(log.questionId);
    }
  }

  // 昨日是否断档
  final yesterdayStart = dayStart.subtract(const Duration(days: 1));
  final yesterdayEvents = await (db.select(db.learningEvents)
        ..where((t) =>
            t.at.isBiggerOrEqualValue(yesterdayStart) &
            t.at.isSmallerThanValue(dayStart))
        ..limit(1))
      .get();
  final missedYesterday = yesterdayEvents.isEmpty;

  final input = GrowthInput(
    reviewDone: reviewEvents.length,
    reviewDue: dueCards.length + reviewEvents.length,
    newQuestions: newQuestions.length,
    masteryGains: masteryGains,
    exerciseDone: exercisesToday.length,
    streak: streak,
    missedYesterday: missedYesterday,
    lapseRecoveries: lapseRecoveries,
    lapses: lapses,
  );

  // 3) 计算三能力
  final calc = GrowthEngine.calculate(input);
  final scores = calc.scores;

  // 4) 快照落库
  await _upsertSnapshot(db, now, scores, input);

  // 5) 连续天数里程碑成就（成长记忆）
  const milestones = [3, 7, 30, 100];
  if (milestones.contains(streak)) {
    final existing = await (db.select(db.learningEvents)
          ..where((t) =>
              t.eventType.equals('streak_milestone') &
              t.at.isBiggerOrEqualValue(dayStart)))
        .get();
    if (existing.isEmpty) {
      await db.into(db.learningEvents).insert(
            LearningEventsCompanion.insert(
              eventType: 'streak_milestone',
              at: now,
              payload: Value(jsonEncode({'streak': streak})),
            ),
          );
    }
  }

  // 6) NextStep（注入 AI 学习路径建议）
  NextStepEngine.injectedPathSuggestion = null;
  try {
    final advisor = AiPathAdvisor(
      AiProviderRepository(db),
      ref.watch(sharedPreferencesProvider),
    );
    NextStepEngine.injectedPathSuggestion = advisor.cachedSuggestion;
  } catch (_) {}
  final nextStep = await NextStepEngine.suggest(db, at: now);
  final moments = await GrowthMemoryFeed.recent(db, at: now);

  return GrowthHomeData(
    scores: scores,
    hasAnyActivity: calc.hasAnyActivity,
    identity: GrowthIdentity.describe(scores),
    strongest: GrowthIdentity.strongest(scores),
    streak: streak,
    nextStep: nextStep,
    moments: moments,
    dueReviewCount: dueCards.length,
    reviewCompletedToday: reviewEvents.length,
    reviewDueTotal: dueCards.length + reviewEvents.length,
    newQuestionsToday: newQuestions.length,
  );
});

/// 连续天数：从今天往回数，有学习事件的天数
Future<int> _computeStreak(AppDatabase db, DateTime now) async {
  var streak = 0;
  for (var i = 0; i < 365; i++) {
    final day = DateTime(now.year, now.month, now.day - i);
    final next = day.add(const Duration(days: 1));
    final events = await (db.select(db.learningEvents)
          ..where((t) =>
              t.at.isBiggerOrEqualValue(day) & t.at.isSmallerThanValue(next))
          ..limit(1))
        .get();
    if (events.isNotEmpty) {
      streak++;
    } else if (i == 0) {
      continue; // 今天还没开始不算断
    } else {
      break;
    }
  }
  return streak;
}

Future<void> _upsertSnapshot(
  AppDatabase db,
  DateTime now,
  GrowthScores scores,
  GrowthInput input,
) async {
  final date =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final existing = await (db.select(db.growthMetrics)
        ..where((t) => t.date.equals(date)))
      .get();

  final snapshotJson = jsonEncode({
    'input': {
      'reviewDone': input.reviewDone,
      'reviewDue': input.reviewDue,
      'newQuestions': input.newQuestions,
      'masteryGains': input.masteryGains,
      'exerciseDone': input.exerciseDone,
      'lapses': input.lapses,
      'lapseRecoveries': input.lapseRecoveries,
      'missedYesterday': input.missedYesterday,
    },
  });

  if (existing.isEmpty) {
    await db.into(db.growthMetrics).insert(
          GrowthMetricsCompanion.insert(
            date: date,
            learningScore: Value(scores.learning),
            focusScore: const Value(0), // 专注域已删除，保留列兼容
            persistenceScore: Value(scores.persistence),
            recoveryScore: Value(scores.recovery),
            reviewDone: Value(input.reviewDone),
            reviewDue: Value(input.reviewDue),
            streak: Value(input.streak),
            snapshotJson: Value(snapshotJson),
          ),
        );
  } else {
    await (db.update(db.growthMetrics)..where((t) => t.date.equals(date)))
        .write(GrowthMetricsCompanion(
      learningScore: Value(scores.learning),
      persistenceScore: Value(scores.persistence),
      recoveryScore: Value(scores.recovery),
      reviewDone: Value(input.reviewDone),
      reviewDue: Value(input.reviewDue),
      streak: Value(input.streak),
      snapshotJson: Value(snapshotJson),
    ));
  }
}
