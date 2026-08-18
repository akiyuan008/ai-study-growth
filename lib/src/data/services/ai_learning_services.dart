import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_message.dart';
import '../../data/repositories/ai_provider_repository.dart';
import '../../data/repositories/review_repository.dart';

/// AI 复习规划（Part 3.2）：
/// 基础排期由 FSRS 确定性算法保证稳定；AI 负责智能优先级排序与动态策略。
class AiReviewPlanner {
  AiReviewPlanner(this._repo);

  final AiProviderRepository _repo;

  /// 确定性优先级（兜底，永远可用）：到期最早 + 掌握度最低优先
  List<DueReviewItem> deterministicOrder(List<DueReviewItem> items) {
    final sorted = [...items]..sort((a, b) {
        final byDue = a.card.due.compareTo(b.card.due);
        if (byDue != 0) return byDue;
        return a.question.masteryLevel.compareTo(b.question.masteryLevel);
      });
    return sorted;
  }

  /// AI 智能重排（失败回落确定性顺序，不阻塞）
  Future<List<DueReviewItem>> smartOrder(List<DueReviewItem> items) async {
    if (items.length <= 1) return items;
    final client = await _buildClient();
    if (client == null) return deterministicOrder(items);

    try {
      final summary = <Map<String, dynamic>>[
        for (var i = 0; i < items.length; i++)
          {
            'index': i,
            'stem': items[i].question.stem.length > 40
                ? '${items[i].question.stem.substring(0, 40)}…'
                : items[i].question.stem,
            'subject': items[i].question.subject,
            'mastery': items[i].question.masteryLevel,
            'overdueHours': DateTime.now()
                .difference(items[i].card.due)
                .inHours
                .clamp(0, 1000),
          },
      ];
      final raw = await client.chat(
        messages: [
          const AiMessage(
            role: 'system',
            content: '你是复习规划助手。根据到期复习队列给出优先级排序。'
                '策略：严重超期与低掌握度优先；同科目尽量连续。'
                '只输出 JSON：{"order":[索引数组]}，不要解释。',
          ),
          AiMessage(role: 'user', content: jsonEncode(summary)),
        ],
        temperature: 0.1,
        maxTokens: 256,
      );
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start < 0 || end <= start) return deterministicOrder(items);
      final json = jsonDecode(raw.substring(start, end + 1));
      final order = (json as Map<String, dynamic>)['order'];
      if (order is! List) return deterministicOrder(items);
      final indices = order
          .map((e) => (e as num).toInt())
          .where((i) => i >= 0 && i < items.length)
          .toList();
      // 去重 + 补全漏掉的索引
      final seen = <int>{};
      final result = <DueReviewItem>[];
      for (final i in indices) {
        if (seen.add(i)) result.add(items[i]);
      }
      for (var i = 0; i < items.length; i++) {
        if (seen.add(i)) result.add(items[i]);
      }
      return result;
    } catch (_) {
      return deterministicOrder(items);
    }
  }

  Future<AiClient?> _buildClient() async {
    final config = await _repo.defaultProvider();
    if (config == null) return null;
    return _repo.buildClient(config.id);
  }
}

/// 知识点学习路径建议（Part 3.3）：
/// AI 分析错题本知识点分布与掌握度 → 生成学习路径建议（NextStep 核心数据源）。
class AiPathAdvisor {
  AiPathAdvisor(this._repo, this._prefs);

  final AiProviderRepository _repo;
  final SharedPreferences _prefs;
  static const _cacheKey = 'advisor.learning_path';
  static const _cacheDateKey = 'advisor.learning_path_date';

  String? get cachedSuggestion => _prefs.getString(_cacheKey);

  /// 生成（或读当日缓存）
  Future<String?> suggest(List<KnowledgePointStat> stats) async {
    if (stats.isEmpty) return null;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_prefs.getString(_cacheDateKey) == today && cachedSuggestion != null) {
      return cachedSuggestion;
    }

    final client = await _buildClient();
    if (client == null) return cachedSuggestion;

    try {
      final summary = [
        for (final s in stats)
          '知识点「${s.name}」：${s.questionCount} 题，平均掌握度 ${s.avgMastery.toStringAsFixed(1)}/5',
      ].join('\n');
      final raw = await client.chat(
        messages: [
          const AiMessage(
            role: 'system',
            content: '你是学习路径规划师。根据错题本的知识点分布与掌握度，'
                '给出一句话学习路径建议（先巩固什么、再复习什么），'
                '不超过 50 字，直接输出建议文本，不要任何前缀或格式。',
          ),
          AiMessage(role: 'user', content: summary),
        ],
        temperature: 0.4,
        maxTokens: 128,
      );
      final text = raw.trim();
      if (text.isNotEmpty) {
        await _prefs.setString(_cacheKey, text);
        await _prefs.setString(_cacheDateKey, today);
        return text;
      }
    } catch (_) {}
    return cachedSuggestion;
  }

  Future<AiClient?> _buildClient() async {
    final config = await _repo.defaultProvider();
    if (config == null) return null;
    return _repo.buildClient(config.id);
  }
}

/// 知识点统计（聚合视图）
class KnowledgePointStat {
  const KnowledgePointStat({
    required this.id,
    required this.name,
    required this.questionCount,
    required this.avgMastery,
  });

  final String id;
  final String name;
  final int questionCount;
  final double avgMastery;
}
