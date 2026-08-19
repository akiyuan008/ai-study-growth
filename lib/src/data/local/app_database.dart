import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/discipline_tables.dart';
import 'tables/growth_tables.dart';
import 'tables/learning_tables.dart';

part 'app_database.g.dart';

/// 全系统唯一事实源。
///
/// 设计原则（事件溯源 + 实体表混合模型）：
/// - 行为与成长数据走事件流：[LearningEvents] / [FocusEvents] → [GrowthMetrics] 快照
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
  // 自律域实体 + 行为事件流
  FocusSessions,
  FocusEvents,
  Missions,
  // 成长引擎
  LearningEvents,
  GrowthMetrics,
  // AI 配置
  AiProviders,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
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
      focusSessions,
      focusEvents,
      missions,
      learningEvents,
      growthMetrics,
      aiProviders,
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
