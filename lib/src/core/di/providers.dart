import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';

/// 全局数据库句柄。main() 中初始化后通过 override 注入；
/// 测试用 [openAppDatabaseMemory] override。
final databaseProvider = Provider<AppDatabase>((ref) {
  return openAppDatabase();
});
