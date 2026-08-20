import 'dart:convert';

/// 从 AI 原始文本中提取 JSON 对象（剥掉围栏与噪声）。
///
/// 容错策略：
/// 1. 剥 markdown 代码围栏
/// 2. 定位第一个 { 到最后一个 }
/// 3. 解码失败时尝试去除尾逗号后重试
Map<String, dynamic>? extractJsonObject(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;

  // 剥 markdown 围栏
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
  final fm = fence.firstMatch(text);
  if (fm != null) text = fm.group(1)!.trim();

  // 定位第一个 { 到最后一个 }
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  final candidate = text.substring(start, end + 1);

  try {
    final decoded = jsonDecode(candidate);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    // 常见修复：去除尾逗号
    try {
      final repaired = candidate.replaceAllMapped(
        RegExp(r',\s*([}\]])'),
        (m) => m.group(1)!,
      );
      final decoded = jsonDecode(repaired);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return null;
}
