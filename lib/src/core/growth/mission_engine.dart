import 'dart:convert';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';

const _uuid = Uuid();

/// 任务引擎 —— 「复习即任务」的执行体。
///
/// 职责：
/// 1. 每日生成：到期复习 → 自动注册当日 Mission（source=review_engine）
/// 2. 持续评估：今日 review_done 事件数达标 → Mission 完成
/// P4 之后：NextStep 建议也可生成 Mission（source=next_step）
abstract final class MissionEngine {
  /// 生成今日任务（幂等：同一天同一来源只建一个）
  static Future<List<String>> generateDailyMissions(
    AppDatabase db, {
    required DateTime now,
  }) async {
    final created = <String>[];
    final today = _dateStr(now);

    // 到期复习任务
    final dueCards = await (db.select(db.reviewCards)
          ..where((t) => t.due.isSmallerOrEqualValue(now)))
        .get();
    if (dueCards.isNotEmpty) {
      final exists = await (db.select(db.missions)
            ..where((t) =>
                t.source.equals('review_engine') &
                t.scheduledFor.equals(today)))
          .get();
      if (exists.isEmpty) {
        final id = _uuid.v4();
        await db.into(db.missions).insert(
              MissionsCompanion.insert(
                id: id,
                title: '完成 ${dueCards.length} 道到期复习',
                source: const Value('review_engine'),
                scheduledFor: today,
                requirement: Value(jsonEncode({
                  'type': 'review_done',
                  'count': dueCards.length,
                })),
                createdAt: now,
              ),
            );
        created.add(id);
      }
    }
    return created;
  }

  /// 评估进行中的任务是否达标（每次复习评分后调用）
  static Future<int> evaluateMissions(AppDatabase db, {DateTime? at}) async {
    final now = at ?? DateTime.now();
    final today = _dateStr(now);
    final dayStart = DateTime(now.year, now.month, now.day);

    final pending = await (db.select(db.missions)
          ..where((t) => t.status.isIn(['pending', 'active'])))
        .get();

    // 今日 review_done 事件数
    final reviewEvents = await (db.select(db.learningEvents)
          ..where((t) =>
              t.eventType.equals('review_done') &
              t.at.isBiggerOrEqualValue(dayStart)))
        .get();
    final reviewDoneCount = reviewEvents.length;

    var completed = 0;
    for (final mission in pending) {
      final req = _decodeRequirement(mission.requirement);
      final done = switch (req['type']) {
        'review_done' =>
          reviewDoneCount >= ((req['count'] as num?)?.toInt() ?? 0),
        _ => false,
      };
      if (done) {
        completed++;
        await (db.update(db.missions)..where((t) => t.id.equals(mission.id)))
            .write(MissionsCompanion(
          status: const Value('done'),
          completedAt: Value(now),
        ));
        await db.into(db.learningEvents).insert(
              LearningEventsCompanion.insert(
                eventType: 'mission_done',
                at: now,
                payload: Value(jsonEncode({'missionId': mission.id})),
              ),
            );
      } else if (mission.scheduledFor == today && mission.status == 'pending') {
        await (db.update(db.missions)..where((t) => t.id.equals(mission.id)))
            .write(const MissionsCompanion(status: Value('active')));
      }
    }
    return completed;
  }

  /// 今日任务列表（成长首页展示）
  static Future<List<Mission>> todayMissions(AppDatabase db,
      {DateTime? at}) async {
    final now = at ?? DateTime.now();
    return (db.select(db.missions)
          ..where((t) => t.scheduledFor.equals(_dateStr(now)))
          ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
        .get();
  }

  static Map<String, dynamic> _decodeRequirement(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
