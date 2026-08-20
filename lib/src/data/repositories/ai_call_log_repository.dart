import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/local/app_database.dart';

/// AI 调用日志条目（UI 用）
class AiCallLogEntry {
  const AiCallLogEntry({
    required this.id,
    required this.purpose,
    required this.requestBody,
    required this.responseBody,
    required this.httpStatus,
    required this.success,
    this.errorTier,
    required this.durationMs,
    required this.at,
  });

  final int id;
  final String purpose;
  final String requestBody;
  final String responseBody;
  final int httpStatus;
  final bool success;
  final String? errorTier;
  final int durationMs;
  final DateTime at;
}

/// AI 调用日志 Repository（补钉 A）
class AiCallLogRepository {
  AiCallLogRepository(this._db);

  final AppDatabase _db;

  /// 写入一条日志
  Future<int> log({
    required String purpose,
    required String requestBody,
    required String responseBody,
    required int httpStatus,
    required bool success,
    String? errorTier,
    required int durationMs,
  }) {
    return _db.into(_db.aiCallLogs).insert(AiCallLogsCompanion.insert(
          purpose: purpose,
          requestBody: requestBody,
          responseBody: responseBody,
          httpStatus: Value(httpStatus),
          success: Value(success),
          errorTier: Value(errorTier),
          durationMs: Value(durationMs),
          at: DateTime.now(),
        ));
  }

  /// 查询最近 N 条
  Future<List<AiCallLogEntry>> recent({int limit = 100}) async {
    final rows = await (_db.select(_db.aiCallLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.at)])
          ..limit(limit))
        .get();
    return rows
        .map((r) => AiCallLogEntry(
              id: r.id,
              purpose: r.purpose,
              requestBody: r.requestBody,
              responseBody: r.responseBody,
              httpStatus: r.httpStatus,
              success: r.success,
              errorTier: r.errorTier,
              durationMs: r.durationMs,
              at: r.at,
            ))
        .toList();
  }

  /// 清空
  Future<void> clear() => _db.delete(_db.aiCallLogs).go();
}

final aiCallLogRepositoryProvider = Provider<AiCallLogRepository>((ref) {
  return AiCallLogRepository(ref.watch(databaseProvider));
});

/// Provider: 最近 100 条日志
final aiCallLogListProvider =
    FutureProvider.autoDispose<List<AiCallLogEntry>>((ref) {
  final repo = ref.watch(aiCallLogRepositoryProvider);
  return repo.recent(limit: 100);
});
