import 'package:drift/drift.dart';

/// 学习域事件流（事件溯源）—— 成长引擎的输入之一
class LearningEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// capture / analysis_done / review_done / exercise_done / followup_asked ...
  TextColumn get eventType => text()();
  TextColumn get questionId => text().nullable()();
  DateTimeColumn get at => dateTime()();

  /// 附加事实，JSON（如掌握度变化、复习评分）
  TextColumn get payload => text().withDefault(const Constant('{}'))();
}

/// 四能力每日快照 —— 成长引擎的输出。
/// 成长趋势图直接读本表，不做实时全量重算。
class GrowthMetrics extends Table {
  /// yyyy-MM-dd，一天一行
  TextColumn get date => text()();

  /// 学习 / 坚持 / 恢复，0-100（专注域已删除，三能力模型）
  RealColumn get learningScore => real().withDefault(const Constant(0))();
  RealColumn get persistenceScore => real().withDefault(const Constant(0))();
  RealColumn get recoveryScore => real().withDefault(const Constant(0))();

  /// 当日事实汇总（供快照解释与审计）
  IntColumn get reviewDone => integer().withDefault(const Constant(0))();
  IntColumn get reviewDue => integer().withDefault(const Constant(0))();
  IntColumn get streak => integer().withDefault(const Constant(0))();

  /// 完整计算明细，JSON
  TextColumn get snapshotJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {date};
}

/// AI 服务商配置。apiKey 本体存 flutter_secure_storage，
/// 这里只存 keyRef（secure storage 的键名），数据库不落密钥。
class AiProviders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// OpenAI 兼容 Base URL，如 https://api.openai.com/v1
  TextColumn get baseUrl => text()();
  TextColumn get model => text()();

  /// flutter_secure_storage 中存放 apiKey 的键名
  TextColumn get keyRef => text()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// AI 调用日志（补钉 A）：留存每次 AI 调用的请求/响应/状态，便于诊断与验收。
class AiCallLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 用途：classify（知识点分类）/ split（拆题）/ analyze（解析）/ exercise（举一反三）/ review_plan（复习规划）/ path_advice（路径建议）
  TextColumn get purpose => text()();

  /// 请求体 JSON
  TextColumn get requestBody => text()();

  /// 响应体 JSON 或文本摘要
  TextColumn get responseBody => text()();

  /// HTTP 状态码
  IntColumn get httpStatus => integer().withDefault(const Constant(0))();

  /// 是否成功
  BoolColumn get success => boolean().withDefault(const Constant(false))();

  /// 错误档位（AiErrorTier 名），可空
  TextColumn get errorTier => text().nullable()();

  /// 耗时（毫秒）
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  DateTimeColumn get at => dateTime()();
}
