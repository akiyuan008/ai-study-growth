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

/// 知识点实体（层级路径 Part 3.2：subject/version/book/chapter/lesson/point）
class KnowledgePoints extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text().withDefault(const Constant(''))();

  /// 教材版本，如 人教版（可推断必须可改）
  TextColumn get version => text().withDefault(const Constant(''))();

  /// 册别，如 八年级上册
  TextColumn get book => text().withDefault(const Constant(''))();

  /// 章
  TextColumn get chapter => text().withDefault(const Constant(''))();

  /// 节
  TextColumn get lesson => text().withDefault(const Constant(''))();

  /// 知识点名称（最末级）
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

  /// FSRS 状态：0 new / 1 learning / 2 review / 3 relearning
  IntColumn get state => integer().withDefault(const Constant(0))();

  /// FSRS 学习/再学习阶段步序（review 状态为 null）
  IntColumn get step => integer().nullable()();

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
@DataClassName('AiMessageRow')
class AiMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text().nullable()();

  /// user / assistant / system
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// 题库飞轮（Part 3.5）：拍题与用题均入库；
/// 多轮举一反三每轮优先未用真题。
class QuestionBank extends Table {
  /// uuid
  TextColumn get id => text()();

  /// 来源题目（用户错题入库时关联）
  TextColumn get sourceQuestionId => text().nullable()();

  /// 关联知识点
  TextColumn get knowledgePointId => text().nullable()();

  /// 科目（Part 3.5 扩展）
  TextColumn get subject => text().withDefault(const Constant(''))();

  /// 题型：choice / fill / solve（Part 3.5 扩展）
  TextColumn get questionType => text().withDefault(const Constant('solve'))();

  /// 难度：easy / medium / hard（Part 3.5 扩展）
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();

  /// 题目内容 JSON：{question, options, answer, explanation}
  TextColumn get content => text()();

  /// real_exam（用户真题）/ ai_cited（AI 真题引用）/ ai_generated（AI 拟题）
  TextColumn get kind => text()();

  /// UI 来源标签：真题·来自你的题库 / 真题引用·2023全国甲卷 / 来源待核实 / AI 拟题
  TextColumn get sourceLabel => text()();

  /// 出处引用原文（L2：年份+地区+考卷名；Part 3.5 扩展）
  TextColumn get sourceCitation => text().nullable()();

  /// 已用于练习的次数（优先未用真题）
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 解析任务（拍题 → 拆题 → 逐题解析 的状态机载体）。
/// 串行队列处理；失败单题可单独重试；部分成功可只保存成功题。
class AnalysisJobs extends Table {
  /// uuid
  TextColumn get id => text()();

  /// 题目照片本地路径
  TextColumn get imagePath => text()();

  /// pending / splitting / analyzing / waiting_confirm / saved / abandoned / failed
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// 拆题结果，JSON：[{index, text}]
  TextColumn get splitResult => text().withDefault(const Constant('[]'))();

  /// 逐题解析结果，JSON：[{index, status, result?, error?}]
  TextColumn get results => text().withDefault(const Constant('[]'))();

  /// 任务级错误（拆题失败等）
  TextColumn get error => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
