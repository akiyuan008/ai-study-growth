import 'package:drift/drift.dart' hide Column, Table;

import '../../data/local/app_database.dart';

/// NextStep 建议（成长引擎的输出，闭环的最后一环）
class NextStep {
  const NextStep({
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.route,
  });

  final String title;
  final String reason;
  final String actionLabel;

  /// GoRouter 路径
  final String route;
}

/// NextStep 规则引擎 —— 按优先级给出「下一步最该做什么」。
///
/// 规则顺序即产品价值观：先还记忆债（复习），再练专注，再摄入新题。
abstract final class NextStepEngine {
  /// 外部注入的学习路径建议（Part 3.3：AI 知识点规划是 NextStep 核心数据源）
  static String? injectedPathSuggestion;

  static Future<NextStep> suggest(AppDatabase db, {DateTime? at}) async {
    final now = at ?? DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);

    // 0) AI 学习路径建议（当日有效）优先级最高
    final path = injectedPathSuggestion;
    if (path != null && path.isNotEmpty) {
      return NextStep(
        title: '今日学习路径',
        reason: path,
        actionLabel: '去复习',
        route: '/review',
      );
    }

    // 1) 到期复习优先
    final due = await (db.select(db.reviewCards)
          ..where((t) => t.due.isSmallerOrEqualValue(now)))
        .get();
    if (due.isNotEmpty) {
      return NextStep(
        title: '先还今天的记忆债',
        reason: '有 ${due.length} 道题到了复习节点，趁记忆还热乎。',
        actionLabel: '去复习',
        route: '/review',
      );
    }

    // 2) 今日还没专注过 → 建议一次专注
    final todaySessions = await (db.select(db.focusSessions)
          ..where((t) => t.startedAt.isBiggerOrEqualValue(dayStart)))
        .get();
    final focusMs = todaySessions.fold<int>(0, (sum, s) => sum + s.focusMs);
    if (focusMs < 25 * 60 * 1000) {
      return NextStep(
        title: '来一段 25 分钟专注',
        reason: focusMs == 0 ? '今天还没有专注记录，先从一小段开始。' : '今天专注还不够，再来一段把它做扎实。',
        actionLabel: '开始专注',
        route: '/focus',
      );
    }

    // 3) 最近 3 天没有新题摄入 → 建议拍题
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final recentQuestions = await (db.select(db.questionRecords)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(threeDaysAgo)))
        .get();
    if (recentQuestions.isEmpty) {
      return NextStep(
        title: '拍一道最近的错题',
        reason: '已经 3 天没有新题入库，把新漏洞变成成长资产。',
        actionLabel: '去拍题',
        route: '/capture',
      );
    }

    // 4) 默认：巩固循环
    return NextStep(
      title: '节奏很好，保持住',
      reason: '复习和专注都在轨道上，按自己的节奏继续。',
      actionLabel: '看看错题本',
      route: '/notebook',
    );
  }
}

/// 成长事件时间线（成长记忆）
class GrowthMoment {
  const GrowthMoment({
    required this.at,
    required this.label,
    required this.kind,
  });

  final DateTime at;
  final String label;

  /// learning / focus / mission
  final String kind;
}

/// 从双域事件流聚合最近的成长瞬间
abstract final class GrowthMemoryFeed {
  static Future<List<GrowthMoment>> recent(AppDatabase db,
      {int limit = 8, DateTime? at}) async {
    final moments = <GrowthMoment>[];

    final learning = await (db.select(db.learningEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.at)])
          ..limit(limit))
        .get();
    for (final e in learning) {
      moments.add(GrowthMoment(
        at: e.at,
        kind: e.eventType == 'mission_done' ? 'mission' : 'learning',
        label: switch (e.eventType) {
          'analysis_done' => '新题入库',
          'question_saved' => '新题入库',
          'review_done' => '完成一次复习',
          'mission_done' => '完成一个任务',
          'streak_milestone' => '连续学习里程碑达成',
          _ => e.eventType,
        },
      ));
    }

    final sessions = await (db.select(db.focusSessions)
          ..where((t) => t.status.isIn(['completed', 'aborted']))
          ..orderBy([(t) => OrderingTerm.desc(t.endedAt)])
          ..limit(limit))
        .get();
    for (final s in sessions) {
      moments.add(GrowthMoment(
        at: s.endedAt ?? s.startedAt,
        kind: 'focus',
        label: '专注 ${s.focusMs ~/ 60000} 分钟',
      ));
    }

    moments.sort((a, b) => b.at.compareTo(a.at));
    return moments.take(limit).toList();
  }
}

/// 当日成长输入聚合（喂给 GrowthEngine）
abstract final class GrowthInputAggregator {
  /// 从 Drift 事实表聚合某一天的 GrowthInput 原料
  static Future<Map<String, dynamic>> collect(
    AppDatabase db, {
    required DateTime now,
    required int streak,
  }) async {
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // 自律域
    final sessions = await (db.select(db.focusSessions)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(dayStart) &
              t.startedAt.isSmallerThanValue(dayEnd)))
        .get();
    final focusMs = sessions.fold<int>(0, (sum, s) => sum + s.focusMs);
    final distractions =
        sessions.fold<int>(0, (sum, s) => sum + s.distractionCount);

    // 学习域
    final reviewEvents = await (db.select(db.learningEvents)
          ..where((t) =>
              t.eventType.equals('review_done') &
              t.at.isBiggerOrEqualValue(dayStart) &
              t.at.isSmallerThanValue(dayEnd)))
        .get();
    final newQuestions = await (db.select(db.questionRecords)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(dayStart) &
              t.createdAt.isSmallerThanValue(dayEnd)))
        .get();

    // 昨日是否断档
    final yesterdayStart = dayStart.subtract(const Duration(days: 1));
    final yesterdaySessions = await (db.select(db.focusSessions)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(yesterdayStart) &
              t.startedAt.isSmallerThanValue(dayStart)))
        .get();
    final yesterdayEvents = await (db.select(db.learningEvents)
          ..where((t) =>
              t.at.isBiggerOrEqualValue(yesterdayStart) &
              t.at.isSmallerThanValue(dayStart)))
        .get();
    final missedYesterday =
        yesterdaySessions.isEmpty && yesterdayEvents.isEmpty;

    return {
      'focusMs': focusMs,
      'distractionCount': distractions,
      'reviewDone': reviewEvents.length,
      'newQuestions': newQuestions.length,
      'missedYesterday': missedYesterday,
    };
  }
}
