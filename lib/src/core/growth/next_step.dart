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
/// 规则顺序即产品价值观：先还记忆债（复习），再摄入新题，再保持节奏。
abstract final class NextStepEngine {
  /// 外部注入的学习路径建议（Part 3.3：AI 知识点规划是 NextStep 核心数据源）
  static String? injectedPathSuggestion;

  static Future<NextStep> suggest(AppDatabase db, {DateTime? at}) async {
    final now = at ?? DateTime.now();

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

    // 2) 最近 3 天没有新题摄入 → 建议拍题
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
      reason: '复习在轨道上，按自己的节奏继续。',
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
