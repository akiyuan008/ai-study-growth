import 'package:drift/drift.dart';

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

/// SM-2 复习卡和复习日志已移至 learning_tables.dart
/// （统一管理所有学习域实体表，避免重复定义冲突）
