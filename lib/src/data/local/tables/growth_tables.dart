import 'package:drift/drift.dart';

/// 学习域事件流（事件溯源）
class LearningEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventType => text()();
  TextColumn get questionId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
}

/// 三能力每日快照 —— 成长引擎的输出。
/// 成长趋势图直接读本表，不做实时全量重算。
class GrowthMetrics extends Table {
  /// yyyy-MM-dd，一天一行
  TextColumn get date => text()();

  /// 学习 / 坚持 / 恢复，0-100（三能力模型）
  RealColumn get learningScore => real().withDefault(const Constant(0))();
  RealColumn get persistenceScore => real().withDefault(const Constant(0))();
  RealColumn get recoveryScore => real().withDefault(const Constant(0))();

  IntColumn get reviewDone => integer().withDefault(const Constant(0))();
  IntColumn get reviewDue => integer().withDefault(const Constant(0))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  TextColumn get snapshotJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {date};
}

/// AI 服务商配置。apiKey 本体存 flutter_secure_storage，
/// 这里只存 keyRef（secure storage 的键名），数据库不落密钥。
class AiProviders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseUrl => text()();
  TextColumn get model => text()();
  TextColumn get keyRef => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// AI 调用日志：留存每次 AI 调用的请求/响应/状态，便于诊断与验收。
class AiCallLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get purpose => text()();
  TextColumn get requestBody => text()();
  TextColumn get responseBody => text()();
  IntColumn get httpStatus => integer().withDefault(const Constant(0))();
  BoolColumn get success => boolean().withDefault(const Constant(false))();
  TextColumn get errorTier => text().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get at => dateTime()();
}

/// SM-2 复习卡（v15 终版：替换 FSRS 字段）
///
/// SM-2 核心字段：
/// - reps: 已复习次数
/// - easinessFactor: 难度因子 EF [1.3, 3.0]
/// - intervalDays: 当前间隔（天）
/// - due: 下次到期时间
/// - lastReviewAt: 上次复习时间
class ReviewCards extends Table {
  TextColumn get id => text()();
  TextColumn get questionId => text()();

  /// SM-2: 已复习次数
  IntColumn get reps => integer().withDefault(const Constant(0))();

  /// SM-2: 难度因子 EF，初始 2.5
  RealColumn get easinessFactor => real().withDefault(const Constant(2.5))();

  /// SM-2: 当前间隔（天）
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();

  DateTimeColumn get due => dateTime()();
  DateTimeColumn get lastReviewAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 复习日志（v15 终版：SM-2 三档评分）
class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get questionId => text()();
  DateTimeColumn get reviewedAt => dateTime()();

  /// SM-2 评分：1=仍错, 3=模糊, 5=已会
  IntColumn get rating => integer()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
