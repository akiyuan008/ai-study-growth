import 'dart:convert';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/growth/growth_engine.dart';
import '../../core/growth/mission_engine.dart';
import '../../core/growth/next_step.dart';
import '../../data/local/app_database.dart';

/// 成长首页的全部数据
class GrowthHomeData {
  const GrowthHomeData({
    required this.scores,
    required this.identity,
    required this.strongest,
    required this.streak,
    required this.nextStep,
    required this.missions,
    required this.moments,
    required this.dueReviewCount,
  });

  final GrowthScores scores;
  final String identity;
  final String strongest;
  final int streak;
  final NextStep nextStep;
  final List<Mission> missions;
  final List<GrowthMoment> moments;
  final int dueReviewCount;
}

/// 成长首页数据聚合：生成任务 → 评估任务 → 聚合事实 → 计算四能力 → 快照落库
final growthHomeProvider =
    FutureProvider.autoDispose<GrowthHomeData>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();

  // 1) 复习即任务：生成 + 评估
  await MissionEngine.generateDailyMissions(db, now: now);
  await MissionEngine.evaluateMissions(db, at: now);

  // 2) 连续天数
  final streak = await _computeStreak(db, now);

  // 3) 聚合当日事实
  final raw = await GrowthInputAggregator.collect(db, now: now, streak: streak);
  final dueCards = await (db.select(db.reviewCards)
        ..where((t) => t.due.isSmallerOrEqualValue(now)))
      .get();

  final input = GrowthInput(
    focusMs: raw['focusMs'] as int,
    distractionCount: raw['distractionCount'] as int,
    distractionRecoveries: await _recoveriesToday(db, now),
    reviewDone: raw['reviewDone'] as int,
    reviewDue: dueCards.length + (raw['reviewDone'] as int),
    newQuestions: raw['newQuestions'] as int,
    masteryGains: await _masteryGainsToday(db, now),
    streak: streak,
    missedYesterday: raw['missedYesterday'] as bool,
  );

  // 4) 计算四能力
  final scores = GrowthEngine.compute(input);

  // 5) 快照落库（growth_metrics 每日快照，成长趋势的数据源）
  await _upsertSnapshot(db, now, scores, input);

  // 6) NextStep 与时间线
  final nextStep = await NextStepEngine.suggest(db, at: now);
  final missions = await MissionEngine.todayMissions(db, at: now);
  final moments = await GrowthMemoryFeed.recent(db, at: now);

  return GrowthHomeData(
    scores: scores,
    identity: GrowthIdentity.describe(scores),
    strongest: GrowthIdentity.strongest(scores),
    streak: streak,
    nextStep: nextStep,
    missions: missions,
    moments: moments,
    dueReviewCount: dueCards.length,
  );
});

/// 连续天数：从今天往回数，有学习事件或专注会话的天数
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
    final sessions = await (db.select(db.focusSessions)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(day) &
              t.startedAt.isSmallerThanValue(next))
          ..limit(1))
        .get();

    if (events.isNotEmpty || sessions.isNotEmpty) {
      streak++;
    } else if (i == 0) {
      // 今天还没开始不算断，继续往前看
      continue;
    } else {
      break;
    }
  }
  return streak;
}

/// 今日分心后回归次数（恢复能力输入）
Future<int> _recoveriesToday(AppDatabase db, DateTime now) async {
  final dayStart = DateTime(now.year, now.month, now.day);
  final events = await (db.select(db.focusEvents)
        ..where((t) =>
            t.eventType.equals('app_foreground') &
            t.at.isBiggerOrEqualValue(dayStart)))
      .get();
  // 回到本应用的 foreground 事件 = 一次恢复
  return events
      .where((e) => e.appPackage == 'com.studygrowth.ai_study_growth')
      .length;
}

/// 今日掌握度提升题目数（学习能力输入）
Future<int> _masteryGainsToday(AppDatabase db, DateTime now) async {
  final dayStart = DateTime(now.year, now.month, now.day);
  final events = await (db.select(db.learningEvents)
        ..where((t) =>
            t.eventType.equals('review_done') &
            t.at.isBiggerOrEqualValue(dayStart)))
      .get();
  // 简化：复习评分为 good/easy(3/4) 且进入 review 态视为掌握度提升
  var gains = 0;
  for (final e in events) {
    try {
      final payload = jsonDecode(e.payload) as Map<String, dynamic>;
      if (payload['state'] == 'review') gains++;
    } catch (_) {}
  }
  return gains;
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
      'focusMs': input.focusMs,
      'distractionCount': input.distractionCount,
      'reviewDone': input.reviewDone,
      'reviewDue': input.reviewDue,
      'newQuestions': input.newQuestions,
      'masteryGains': input.masteryGains,
      'missedYesterday': input.missedYesterday,
    },
  });

  if (existing.isEmpty) {
    await db.into(db.growthMetrics).insert(
          GrowthMetricsCompanion.insert(
            date: date,
            learningScore: Value(scores.learning),
            focusScore: Value(scores.focus),
            persistenceScore: Value(scores.persistence),
            recoveryScore: Value(scores.recovery),
            focusMs: Value(input.focusMs),
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
      focusScore: Value(scores.focus),
      persistenceScore: Value(scores.persistence),
      recoveryScore: Value(scores.recovery),
      focusMs: Value(input.focusMs),
      reviewDone: Value(input.reviewDone),
      reviewDue: Value(input.reviewDue),
      streak: Value(input.streak),
      snapshotJson: Value(snapshotJson),
    ));
  }
}
