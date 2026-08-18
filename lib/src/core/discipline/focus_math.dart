library;

/// focusMath —— 专注时长的区间数学。
///
/// 原则：真实专注时长 = 会话期间所有「真正在专注」的区间并集长度。
/// 切出 App 的时间一段都不算。所有函数纯函数，便于测试。

/// 一个专注区间 [start, end)
class FocusSegment {
  const FocusSegment({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get ms => end.difference(start).inMilliseconds;
}

/// 合并重叠/相邻区间（按 start 排序后线性扫描）
List<FocusSegment> mergeFocusSegments(List<FocusSegment> segments) {
  if (segments.length <= 1) return List.of(segments);
  final sorted = [...segments]..sort((a, b) => a.start.compareTo(b.start));

  final merged = <FocusSegment>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final cur = sorted[i];
    final last = merged.last;
    if (!cur.start.isAfter(last.end)) {
      // 重叠或相邻 → 扩展
      merged[merged.length - 1] = FocusSegment(
        start: last.start,
        end: cur.end.isAfter(last.end) ? cur.end : last.end,
      );
    } else {
      merged.add(cur);
    }
  }
  return merged;
}

/// 总专注毫秒数
int totalFocusMs(List<FocusSegment> segments) =>
    mergeFocusSegments(segments).fold(0, (sum, s) => sum + s.ms);

/// 把「会话总时长」与「专注区间」对比，得到分心毫秒数
int totalDistractionMs({
  required DateTime sessionStart,
  required DateTime sessionEnd,
  required List<FocusSegment> focusSegments,
}) {
  final total = sessionEnd.difference(sessionStart).inMilliseconds;
  final focus = totalFocusMs(focusSegments);
  return (total - focus).clamp(0, total);
}

/// 分心次数统计：连续分心合并为一次（事件流去抖）
int countDistractions(List<DateTime> distractionStarts) =>
    distractionStarts.length;
