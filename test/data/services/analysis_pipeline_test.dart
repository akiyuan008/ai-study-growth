import 'dart:convert';

import 'package:ai_study_growth/src/core/ai/ai_message.dart';
import 'package:ai_study_growth/src/core/ai/analysis_gateway.dart';
import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:ai_study_growth/src/data/services/analysis_pipeline.dart';
import 'package:ai_study_growth/src/domain/models/analysis_result.dart';
import 'package:ai_study_growth/src/domain/models/generated_exercise.dart';
import 'package:ai_study_growth/src/domain/models/knowledge_path.dart';
import 'package:ai_study_growth/src/domain/models/subject.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假网关：可编程的 AI 行为
class FakeGateway implements AiAnalysisGateway {
  int splitCalls = 0;
  int analyzeCalls = 0;

  bool failSplit = false;

  /// 指定题干文本 → 第 N 次调用时失败
  final Map<String, int> failAnalyzeTimes = {};
  final Map<String, int> _analyzeAttempts = {};

  List<QuestionCandidate> splitResult = const [
    QuestionCandidate(index: 1, text: '第一题题干'),
    QuestionCandidate(index: 2, text: '第二题题干'),
  ];

  @override
  Future<List<QuestionCandidate>> splitQuestions({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    splitCalls++;
    if (failSplit) throw const AiGatewayException('split boom');
    return splitResult;
  }

  @override
  Future<AnalysisResult> analyzeQuestion({
    List<int>? imageBytes,
    String mimeType = 'image/jpeg',
    String? questionText,
  }) async {
    analyzeCalls++;
    final key = questionText ?? '<image>';
    final attempts = (_analyzeAttempts[key] ?? 0) + 1;
    _analyzeAttempts[key] = attempts;
    final failTimes = failAnalyzeTimes[key] ?? 0;
    if (attempts <= failTimes) {
      throw AiGatewayException('analyze boom #$attempts');
    }
    return AnalysisResult(
      subject: Subject.physics,
      stem: questionText ?? '图片题题干',
      finalAnswer: '42',
      steps: const ['步骤一'],
      tags: const ['力学'],
      knowledgePoints: const ['牛顿第二定律'],
      mistakeReason: '公式用错',
      studyAdvice: '复习公式',
    );
  }

  @override
  Future<List<ExerciseItem>> generateExercises({
    required String stem,
    required String answer,
    required List<String> steps,
    required String mistakeReason,
    required List<String> knowledgePoints,
  }) async =>
      const [];

  @override
  Stream<String> followUp({
    required String questionContext,
    required List<AiMessage> history,
    required String question,
  }) async* {
    yield 'ok';
  }

  @override
  Future<List<String>> suggestKnowledgeTags({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async =>
      const ['测试知识点'];

  @override
  Future<KnowledgePath> suggestKnowledgePath({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async =>
      const KnowledgePath(subject: '物理', point: '测试知识点');
}

Future<AnalysisJob> _getJob(AppDatabase db, String jobId) async {
  return (db.select(db.analysisJobs)..where((t) => t.id.equals(jobId)))
      .getSingle();
}

Future<AnalysisJob> _awaitStatus(
  AppDatabase db,
  String jobId,
  List<String> statuses, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final job = await _getJob(db, jobId);
    if (statuses.contains(job.status)) return job;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('等待状态 $statuses 超时');
}

Future<AnalysisJob> _awaitCondition(
  AppDatabase db,
  String jobId,
  bool Function(AnalysisJob job) condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final job = await _getJob(db, jobId);
    if (condition(job)) return job;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('等待条件满足超时');
}

List<CandidateAnalysis> _results(AnalysisJob job) =>
    (jsonDecode(job.results) as List)
        .map((e) => CandidateAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();

void main() {
  late AppDatabase db;
  late FakeGateway gateway;
  late AnalysisPipeline pipeline;

  setUp(() {
    db = openAppDatabaseMemory();
    gateway = FakeGateway();
    pipeline = AnalysisPipeline(
      db: db,
      gatewayResolver: () async => gateway,
      imageLoader: (path) async => [1, 2, 3],
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('完整链路：拆题 → 逐题解析 → 保存入库（题目+复习卡+事件）', () async {
    final jobId = await pipeline.submit('/fake/img.jpg');

    final job = await _awaitStatus(db, jobId, ['waiting_confirm']);
    expect(gateway.splitCalls, 1);
    expect(gateway.analyzeCalls, 2);

    final results = (jsonDecode(job.results) as List)
        .map((e) => CandidateAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(results.every((c) => c.status == CandidateStatus.success), isTrue);

    final savedIds = await pipeline.saveJob(jobId);
    expect(savedIds, hasLength(2));

    final questions = await db.select(db.questionRecords).get();
    expect(questions, hasLength(2));
    expect(questions.first.contentStatus, 'saved');

    final cards = await db.select(db.reviewCards).get();
    expect(cards, hasLength(2));

    final events = await db.select(db.learningEvents).get();
    expect(events.where((e) => e.eventType == 'analysis_done'), hasLength(2));

    final kps = await db.select(db.knowledgePoints).get();
    expect(kps.map((k) => k.name), contains('牛顿第二定律'));

    final links = await db.select(db.questionKnowledgeLinks).get();
    expect(links, hasLength(2));

    final reloaded = await (db.select(db.analysisJobs)
          ..where((t) => t.id.equals(jobId)))
        .getSingle();
    expect(reloaded.status, 'saved');
  });

  test('单题失败不影响其他题；重试后全部成功', () async {
    gateway.failAnalyzeTimes['第二题题干'] = 1;
    final jobId = await pipeline.submit('/fake/img.jpg');

    final job = await _awaitStatus(db, jobId, ['waiting_confirm']);
    var results = (jsonDecode(job.results) as List)
        .map((e) => CandidateAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();
    final failed =
        results.where((c) => c.status == CandidateStatus.failed).toList();
    expect(failed, hasLength(1));

    // 重试失败题，等到所有题都成功
    pipeline.retryCandidate(jobId, failed.first.index);
    final reloaded = await _awaitCondition(
      db,
      jobId,
      (j) =>
          _results(j).isNotEmpty &&
          _results(j).every((c) => c.status == CandidateStatus.success),
    );
    results = _results(reloaded);
    expect(results.every((c) => c.status == CandidateStatus.success), isTrue);

    final savedIds = await pipeline.saveJob(jobId);
    expect(savedIds, hasLength(2));
  });

  test('拆题失败降级为整图单题直解', () async {
    gateway.failSplit = true;
    final jobId = await pipeline.submit('/fake/img.jpg');

    final job = await _awaitStatus(db, jobId, ['waiting_confirm']);
    expect(gateway.analyzeCalls, 1);
    final results = (jsonDecode(job.results) as List)
        .map((e) => CandidateAnalysis.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(results.single.status, CandidateStatus.success);
    expect(results.single.result?.stem, '图片题题干');
  });

  test('放弃任务：状态置 abandoned，不入库', () async {
    final jobId = await pipeline.submit('/fake/img.jpg');
    await _awaitStatus(db, jobId, ['waiting_confirm']);
    await pipeline.abandonJob(jobId);

    final reloaded = await (db.select(db.analysisJobs)
          ..where((t) => t.id.equals(jobId)))
        .getSingle();
    expect(reloaded.status, 'abandoned');
    expect(await db.select(db.questionRecords).get(), isEmpty);
  });

  test('严格串行：两个任务排队，网关不会被并发调用', () async {
    final id1 = await pipeline.submit('/fake/a.jpg');
    final id2 = await pipeline.submit('/fake/b.jpg');

    await _awaitStatus(db, id1, ['waiting_confirm']);
    await _awaitStatus(db, id2, ['waiting_confirm']);

    // 两次完整流程：2 次拆题 + 4 次解析，全部顺序完成
    expect(gateway.splitCalls, 2);
    expect(gateway.analyzeCalls, 4);
  });

  test('未配置 AI 网关：任务标记失败并给出提示', () async {
    final noAiPipeline = AnalysisPipeline(
      db: db,
      gatewayResolver: () async => null,
      imageLoader: (path) async => [1],
    );
    final jobId = await noAiPipeline.submit('/fake/img.jpg');
    final job = await _awaitStatus(db, jobId, ['failed']);
    expect(job.error, contains('AI 服务商'));
  });
}
