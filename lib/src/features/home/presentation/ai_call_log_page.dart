import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/ai_call_log_repository.dart';
import '../../../design_system/design_system.dart';

/// AI 调用日志页（补钉 A）：页内可查/可导出，不向用户索要代码层证据
class AiCallLogPage extends ConsumerWidget {
  const AiCallLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(aiCallLogListProvider);

    return Scaffold(
      appBar: growthAppBar(context, title: 'AI 调用日志'),
      body: GrowthBackground(
        child: logsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: GrowthColors.gray3),
                    SizedBox(height: GrowthSpacing.md),
                    Text('暂无调用记录'),
                    SizedBox(height: GrowthSpacing.xs),
                    Text(
                      '配置 AI 服务商并拍题后，\n每次知识点识别的请求/响应会记录在此',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(GrowthSpacing.md),
              itemCount: logs.length,
              itemBuilder: (context, i) => _LogCard(log: logs[i]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final AiCallLogEntry log;

  @override
  Widget build(BuildContext context) {
    final successColor =
        log.success ? GrowthColors.success : GrowthColors.error;
    final fmt = DateFormat('MM-dd HH:mm:ss');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: GrowthSpacing.sm),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
            horizontal: GrowthSpacing.sm, vertical: 0),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: successColor,
          ),
        ),
        title: Text(
          _purposeLabel(log.purpose),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          '${fmt.format(log.at)} · ${log.durationMs}ms · HTTP ${log.httpStatus}'
          '${log.errorTier != null ? ' · ${log.errorTier}' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: GrowthSpacing.md, vertical: GrowthSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('请求',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(GrowthSpacing.sm),
                  decoration: BoxDecoration(
                    color: GrowthColors.gray1,
                    borderRadius: BorderRadius.circular(GrowthRadii.icon),
                  ),
                  child: SelectableText(
                    _prettyJson(log.requestBody),
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: GrowthSpacing.sm),
                Text('响应',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(GrowthSpacing.sm),
                  decoration: BoxDecoration(
                    color: GrowthColors.gray1,
                    borderRadius: BorderRadius.circular(GrowthRadii.icon),
                  ),
                  child: SelectableText(
                    _prettyJson(log.responseBody),
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _purposeLabel(String p) => switch (p) {
        'classify' => '知识点分类',
        'split' => '拆题',
        'analyze' => '题目解析',
        'exercise' => '举一反三',
        'review_plan' => '复习规划',
        'path_advice' => '路径建议',
        _ => p,
      };

  String _prettyJson(String raw) {
    try {
      final decoded = raw.startsWith('{') || raw.startsWith('[')
          ? const JsonDecoder().convert(raw)
          : raw;
      if (decoded is Map || decoded is List) {
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }
}
