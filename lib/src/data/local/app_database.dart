import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/growth_tables.dart';
import 'tables/learning_tables.dart';

part 'app_database.g.dart';

/// 全系统唯一事实源。
///
/// 设计原则（事件溯源 + 实体表混合模型）：
/// - 行为与成长数据走事件流：[LearningEvents] → [GrowthMetrics] 快照
/// - 知识资产走实体表：[QuestionRecords] 等，服务错题本业务查询
/// - 两者通过 question id 关联
@DriftDatabase(tables: [
  // 学习域实体
  QuestionRecords,
  QuestionBank,
  AnalysisJobs,
  KnowledgePoints,
  QuestionKnowledgeLinks,
  ReviewCards,
  ReviewLogs,
  GeneratedExercises,
  AiMessages,
  // 成长引擎
  LearningEvents,
  GrowthMetrics,
  // AI 配置
  AiProviders,
  // AI 调用日志（补钉 A）
  AiCallLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2：知识点层级路径列（Part 3.2）
          if (from < 2) {
            await customStatement(
                'ALTER TABLE knowledge_points ADD COLUMN version TEXT NOT NULL DEFAULT \'\'');
            await customStatement(
                'ALTER TABLE knowledge_points ADD COLUMN book TEXT NOT NULL DEFAULT \'\'');
            await customStatement(
                'ALTER TABLE knowledge_points ADD COLUMN chapter TEXT NOT NULL DEFAULT \'\'');
            await customStatement(
                'ALTER TABLE knowledge_points ADD COLUMN lesson TEXT NOT NULL DEFAULT \'\'');
          }
          // v3：删除自律域表（专注/任务/监控），新增 AiCallLogs
          if (from < 3) {
            await customStatement('DROP TABLE IF EXISTS focus_sessions');
            await customStatement('DROP TABLE IF EXISTS focus_events');
            await customStatement('DROP TABLE IF EXISTS missions');
            await customStatement(
                'CREATE TABLE IF NOT EXISTS ai_call_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, purpose TEXT NOT NULL, request_body TEXT NOT NULL, response_body TEXT NOT NULL, http_status INTEGER NOT NULL, success INTEGER NOT NULL, error_tier TEXT, duration_ms INTEGER NOT NULL, at INTEGER NOT NULL)');
          }
        },
        beforeOpen: (details) async {
          // 外键约束默认关闭，显式开启保证关联完整性
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// 打开指定文件路径的数据库（备份快照临时实例用）
  factory AppDatabase.openFile(String path) =>
      AppDatabase(NativeDatabase(File(path)));

  /// 开发/测试用：全库清空（不删表）
  Future<void> clearAllForTest() async {
    final List<TableInfo<Table, dynamic>> tables = [
      questionRecords,
      questionBank,
      analysisJobs,
      knowledgePoints,
      questionKnowledgeLinks,
      reviewCards,
      reviewLogs,
      generatedExercises,
      aiMessages,
      learningEvents,
      growthMetrics,
      aiProviders,
      aiCallLogs,
    ];
    for (final t in tables) {
      await delete(t).go();
    }
  }
}

/// 生产环境打开数据库：应用文档目录下的单文件
AppDatabase openAppDatabase({String? fileOverride}) {
  return AppDatabase(LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file =
        File(p.join(dir.path, fileOverride ?? 'ai_study_growth.sqlite'));
    return NativeDatabase.createInBackground(file);
  }));
}

/// 测试用内存数据库
AppDatabase openAppDatabaseMemory() => AppDatabase(NativeDatabase.memory());

/// 全局数据库持有者：云备份恢复时关闭并重建实例（Part 4）
abstract final class AppDatabaseHolder {
  static AppDatabase? _instance;

  static AppDatabase get instance => _instance ??= openAppDatabase();

  /// 恢复流程写入新 DB 文件后调用：下次访问重新打开
  static void reopen() {
    _instance = null;
  }
}
