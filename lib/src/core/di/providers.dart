import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';

/// 全局数据库句柄（走 holder，云备份恢复时可重建实例）。
/// 测试用 [openAppDatabaseMemory] override。
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabaseHolder.instance;
});
