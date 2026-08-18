import 'package:drift/drift.dart';

/// 专注会话实体（一次完整的专注/深渊会话）
class FocusSessions extends Table {
  /// uuid
  TextColumn get id => text()();

  /// 关联任务（可空：自由专注）
  TextColumn get missionId => text().nullable()();

  /// 关联题目，JSON 数组 —— “25 分钟吃透这 3 道题”的落地字段
  TextColumn get questionIds => text().withDefault(const Constant('[]'))();

  /// normal / abyss
  TextColumn get mode => text().withDefault(const Constant('normal'))();

  /// active / completed / aborted
  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// 计划时长（毫秒）
  IntColumn get plannedMs => integer().withDefault(const Constant(0))();

  /// 真实专注时长（focusMath 区间去重后，毫秒）—— 只认这个数
  IntColumn get focusMs => integer().withDefault(const Constant(0))();

  IntColumn get distractionCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 行为事件流 —— Kotlin 原生层产出的事实，经 EventChannel 落库。
/// “Kotlin 产事实，Dart 做决策”：这里只存事实，判定在 DisciplineEngine。
class FocusEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 关联会话（可空：监控态事件无会话）
  TextColumn get sessionId => text().nullable()();

  /// app_foreground / app_usage / distraction / lock_shown / lock_dismissed ...
  TextColumn get eventType => text()();

  /// 前台应用包名（app_usage / app_foreground 事件）
  TextColumn get appPackage => text().nullable()();

  DateTimeColumn get at => dateTime()();

  /// 事件持续时长（毫秒，可空）
  IntColumn get durationMs => integer().nullable()();

  /// 附加事实，JSON
  TextColumn get payload => text().withDefault(const Constant('{}'))();
}

/// 任务状态机记录。
/// source 体现融合闭环：manual（手建）/ review_engine（复习即任务）/
/// next_step（成长引擎建议）
class Missions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();

  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// pending / active / done / failed / skipped
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// 计划执行日期 yyyy-MM-dd
  TextColumn get scheduledFor => text()();

  /// 关联题目，JSON 数组（复习任务携带）
  TextColumn get linkedQuestionIds =>
      text().withDefault(const Constant('[]'))();

  /// 完成条件定义，JSON（如 {type:"review_due", count:8} / {type:"focus", ms:1500000}）
  TextColumn get requirement => text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// 完成后发放的 XP
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
