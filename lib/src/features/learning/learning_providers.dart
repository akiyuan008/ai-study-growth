import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_client.dart';
import '../../core/backup/backup_service.dart';
import '../../core/ai/ai_provider_config.dart';
import '../../core/ai/analysis_gateway.dart';
import '../../core/di/providers.dart';
import '../../design_system/growth_theme.dart' show sharedPreferencesProvider;
import '../../data/repositories/ai_call_log_repository.dart';
import '../../data/repositories/ai_config_repository.dart';
import '../../data/repositories/ai_provider_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/question_bank_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/services/ai_learning_services.dart';
import '../../data/services/settings_service.dart';
import '../../data/services/analysis_pipeline.dart';

final aiProviderRepositoryProvider = Provider<AiProviderRepository>((ref) {
  return AiProviderRepository(ref.watch(databaseProvider));
});

/// AI 配置页专用仓储（hydrate / 规范化 / 错误分级）
final aiConfigRepositoryProvider = Provider<AiConfigRepository>((ref) {
  return AiConfigRepository(ref.watch(aiProviderRepositoryProvider));
});

/// 备份状态仓储（Part 4）
final backupStateProvider = Provider<BackupStateRepository>((ref) {
  return BackupStateRepository(ref.watch(sharedPreferencesProvider));
});

/// 备份服务
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    dbFactory: () => ref.read(databaseProvider),
    state: ref.watch(backupStateProvider),
  );
});

/// 默认 AI 服务商配置（未配置时为 null）
final defaultAiConfigProvider = FutureProvider<AiProviderConfig?>((ref) {
  return ref.watch(aiProviderRepositoryProvider).defaultProvider();
});

/// AI 网关：学习域唯一的 AI 入口；未配置时返回 null
/// 补钉 A：接入 AiCallLog，每次 AI 调用写日志
final aiGatewayProvider = FutureProvider<AiAnalysisGateway?>((ref) async {
  final repo = ref.watch(aiProviderRepositoryProvider);
  final config = await repo.defaultProvider();
  if (config == null) return null;
  final client = await repo.buildClient(config.id);
  if (client == null) return null;
  final logRepo = ref.watch(aiCallLogRepositoryProvider);
  return AiAnalysisGatewayImpl(
    client,
    logger: ({required purpose, required requestBody, required responseBody,
        required httpStatus, required success, errorTier, required durationMs}) async {
      await logRepo.log(
        purpose: purpose,
        requestBody: requestBody,
        responseBody: responseBody,
        httpStatus: httpStatus,
        success: success,
        errorTier: errorTier,
        durationMs: durationMs,
      );
    },
  );
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(ref.watch(databaseProvider));
});

/// 应用设置（通知 / 复习提醒时间）
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(sharedPreferencesProvider));
});

/// AI 复习规划（确定性兜底 + AI 智能重排）
final aiReviewPlannerProvider = Provider<AiReviewPlanner>((ref) {
  return AiReviewPlanner(ref.watch(aiProviderRepositoryProvider));
});

/// 知识点学习路径建议（Part 3.3，NextStep 核心数据源）
final aiPathAdvisorProvider = Provider<AiPathAdvisor>((ref) {
  return AiPathAdvisor(
    ref.watch(aiProviderRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(databaseProvider));
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(databaseProvider));
});

/// 题库飞轮仓储
final questionBankRepositoryProvider = Provider<QuestionBankRepository>((ref) {
  return QuestionBankRepository(ref.watch(databaseProvider));
});

/// 解析管线（全局单例，串行队列）
final analysisPipelineProvider =
    ChangeNotifierProvider<AnalysisPipeline>((ref) {
  final db = ref.watch(databaseProvider);
  final pipeline = AnalysisPipeline(
    db: db,
    gatewayResolver: () async => ref.read(aiGatewayProvider.future),
  );
  // 启动恢复中断任务
  Future.microtask(pipeline.resumeInterrupted);
  return pipeline;
});

/// 追问对话（流式）：题目详情页调用
final followUpStreamProvider = Provider<FollowUpHelper>((ref) {
  return FollowUpHelper(ref);
});

class FollowUpHelper {
  const FollowUpHelper(this._ref);

  final Ref _ref;

  Stream<String> ask({
    required String questionContext,
    required List<dynamic> history,
    required String question,
  }) async* {
    final gateway = await _ref.read(aiGatewayProvider.future);
    if (gateway == null) {
      yield '请先在设置中配置 AI 服务商，再来问问题哦。';
      return;
    }
    yield* gateway.followUp(
      questionContext: questionContext,
      history: history.cast(),
      question: question,
    );
  }
}

/// 举一反三生成
final exerciseGeneratorProvider = Provider<ExerciseGenerator>((ref) {
  return ExerciseGenerator(ref);
});

class ExerciseGenerator {
  const ExerciseGenerator(this._ref);

  final Ref _ref;

  Future<List<dynamic>> generate({
    required String stem,
    required String answer,
    required List<String> steps,
    required String mistakeReason,
    required List<String> knowledgePoints,
  }) async {
    final gateway = await _ref.read(aiGatewayProvider.future);
    if (gateway == null) return const [];
    return gateway.generateExercises(
      stem: stem,
      answer: answer,
      steps: steps,
      mistakeReason: mistakeReason,
      knowledgePoints: knowledgePoints,
    );
  }
}

/// AiClient 直接访问（配置页测试连接用）
final aiProviderClientFactory = Provider<AiClientFactory>((ref) {
  return AiClientFactory(ref);
});

class AiClientFactory {
  const AiClientFactory(this._ref);

  final Ref _ref;

  Future<AiClient?> forDefault() async {
    final repo = _ref.read(aiProviderRepositoryProvider);
    final config = await repo.defaultProvider();
    if (config == null) return null;
    return repo.buildClient(config.id);
  }
}
