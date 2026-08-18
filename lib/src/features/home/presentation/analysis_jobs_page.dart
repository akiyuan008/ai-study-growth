import 'dart:convert';

import 'package:drift/drift.dart' hide Column, Table;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/analysis_result.dart';
import '../../learning/learning_providers.dart';

final analysisJobsProvider =
    FutureProvider.autoDispose<List<AnalysisJob>>((ref) async {
  // pipeline 的 notifyListeners 会触发重建
  ref.watch(analysisPipelineProvider);
  final db = ref.watch(databaseProvider);
  return (db.select(db.analysisJobs)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
});

/// 解析任务队列页：任务状态、单题重试、保存/放弃
class AnalysisJobsPage extends ConsumerWidget {
  const AnalysisJobsPage({super.key, this.focusJobId});

  final String? focusJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(analysisJobsProvider);

    return GrowthBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: growthAppBar(
        context,
        title: '解析队列',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const GrowthEmptyState(
              message: '暂无解析任务\n去拍一道题试试',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(GrowthSpacing.lg),
            itemCount: jobs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: GrowthSpacing.md),
            itemBuilder: (context, i) => _JobCard(job: jobs[i]),
          );
        },
      ),
    ));
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job});

  final AnalysisJob job;

  List<CandidateAnalysis> get _results {
    try {
      return (jsonDecode(job.results) as List)
          .map((e) => CandidateAnalysis.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  (String, Color) get _statusInfo => switch (job.status) {
        'pending' => ('排队中', GrowthColors.primary),
        'splitting' => ('正在拆题…', GrowthColors.primary),
        'analyzing' => ('正在解析…', GrowthColors.primary),
        'waiting_confirm' => ('待确认保存', GrowthColors.success),
        'saved' => ('已保存', GrowthColors.success),
        'abandoned' => ('已放弃', GrowthColors.caution),
        _ => ('失败', GrowthColors.caution),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusLabel, statusColor) = _statusInfo;
    final results = _results;
    final hasSuccess = results.any((c) => c.status == CandidateStatus.success);
    final active = job.status == 'waiting_confirm' ||
        (job.status == 'failed' && results.isNotEmpty);

    return GrowthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (File(job.imagePath).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(GrowthRadii.icon),
                  child: Image.file(
                    File(job.imagePath),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: GrowthSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GrowthSpacing.xs),
                    if (job.status == 'splitting' || job.status == 'analyzing')
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        job.error ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          for (final c in results) ...[
            const SizedBox(height: GrowthSpacing.sm),
            _CandidateRow(job: job, candidate: c),
          ],
          if (active) ...[
            const SizedBox(height: GrowthSpacing.md),
            Row(
              children: [
                if (hasSuccess)
                  Expanded(
                    child: GrowthButton(
                      label: '保存',
                      onPressed: () async {
                        final ids = await ref
                            .read(analysisPipelineProvider)
                            .saveJob(job.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已入库 ${ids.length} 道题')),
                          );
                        }
                      },
                    ),
                  ),
                if (hasSuccess) const SizedBox(width: GrowthSpacing.sm),
                Expanded(
                  child: GrowthButton(
                    label: '放弃',
                    variant: GrowthButtonVariant.ghost,
                    onPressed: () =>
                        ref.read(analysisPipelineProvider).abandonJob(job.id),
                  ),
                ),
              ],
            ),
          ],
          if (job.status == 'failed' && results.isEmpty && job.error != null)
            Padding(
              padding: const EdgeInsets.only(top: GrowthSpacing.sm),
              child: GrowthButton(
                label: '重试整个任务',
                variant: GrowthButtonVariant.secondary,
                expanded: true,
                onPressed: () =>
                    ref.read(analysisPipelineProvider).retryJob(job.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateRow extends ConsumerWidget {
  const _CandidateRow({required this.job, required this.candidate});

  final AnalysisJob job;
  final CandidateAnalysis candidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = switch (candidate.status) {
      CandidateStatus.success => const Icon(Icons.check_circle_rounded,
          color: GrowthColors.success, size: 18),
      CandidateStatus.failed =>
        const Icon(Icons.error_rounded, color: GrowthColors.caution, size: 18),
      CandidateStatus.analyzing => const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      CandidateStatus.pending => const Icon(Icons.schedule_rounded,
          color: GrowthColors.primary, size: 18),
    };

    final title = candidate.status == CandidateStatus.success
        ? (candidate.result?.stem ?? '解析完成')
        : candidate.status == CandidateStatus.failed
            ? (candidate.error ?? '解析失败')
            : '第 ${candidate.index} 题';

    return Row(
      children: [
        icon,
        const SizedBox(width: GrowthSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (candidate.status == CandidateStatus.failed)
          TextButton(
            onPressed: () => ref
                .read(analysisPipelineProvider)
                .retryCandidate(job.id, candidate.index),
            child: const Text('重试'),
          ),
      ],
    );
  }
}
