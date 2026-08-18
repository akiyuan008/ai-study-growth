import 'package:drift/drift.dart';

/// 题库实体表 —— 学习域的核心知识资产。
/// 事件流（learning_events）喂成长引擎，实体表服务错题本业务，
/// 两者通过 question id 关联。
class QuestionRecords extends Table {
  /// uuid
  TextColumn get id => text()();

  /// 科目（数学/物理/...）
  TextColumn get subject => text().withDefault(const Constant(''))();

  /// 本地图片路径（题干照片）
  TextColumn get imagePath => text().nullable()();

  /// 题干
  TextColumn get stem => text().withDefault(const Constant(''))();

  /// 答案
  TextColumn get answer => text().nullable()();

  /// 关键步骤
  TextColumn get keySteps => text().nullable()();

  /// 错因
  TextColumn get errorCause => text().nullable()();

  /// AI 解析详情（markdown）
  TextColumn get analysisDetail => text().nullable()();

  /// 短标签，JSON 数组字符串，如 ["压强","力学"]
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// 来源：capture / manual / import
  TextColumn get source => text().withDefault(const Constant('capture'))();

  /// 状态：draft / saved / archived
  TextColumn get contentStatus => text().withDefault(const Constant('draft'))();

  /// 掌握度 0-5（由复习/练习结果驱动，成长引擎读取）
  IntColumn get masteryLevel => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 知识点实体（AI 自动打标沉淀，未来演化为知识点图谱）
class KnowledgePoints extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text().withDefault(const Constant(''))();
  TextColumn get name => text()();
  DateTimeColumn get firstSeenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {subject, name},
      ];
}

/// 题目 ↔ 知识点 多对多关联
class QuestionKnowledgeLinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text()();
  TextColumn get knowledgePointId => text()();
}

/// 间隔复习卡片（P2 接 FSRS 算法，此处预留算法状态列）
class ReviewCards extends Table {
  TextColumn get id => text()();

  /// 关联题目
  TextColumn get questionId => text()();

  /// 到期时间（FSRS due）
  DateTimeColumn get due => dateTime()();

  /// FSRS 状态参数
  RealColumn get stability => real().withDefault(const Constant(0))();
  RealColumn get difficulty => real().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 复习日志（每次评分一条，供成长引擎计算学习能力）
class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text()();

  /// FSRS 评分：1 again / 2 hard / 3 good / 4 easy
  IntColumn get rating => integer()();
  DateTimeColumn get reviewedAt => dateTime()();
  IntColumn get durationMs => integer().nullable()();
}

/// 举一反三生成的练习
class GeneratedExercises extends Table {
  TextColumn get id => text()();

  /// 来源错题
  TextColumn get questionId => text()();

  /// 练习题内容，JSON（题目列表 + 参考答案）
  TextColumn get content => text()();

  /// pending / in_progress / completed / abandoned
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// AI 追问对话记录（挂在某道题下）
class AiMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text().nullable()();

  /// user / assistant / system
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
}
