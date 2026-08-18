import 'package:ai_study_growth/src/core/discipline/focus_math.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime t(int seconds) =>
    DateTime(2026, 8, 18, 10).add(Duration(seconds: seconds));

void main() {
  group('mergeFocusSegments', () {
    test('空区间与单区间', () {
      expect(mergeFocusSegments(const []), isEmpty);
      final single = [FocusSegment(start: t(0), end: t(10))];
      expect(mergeFocusSegments(single), hasLength(1));
    });

    test('重叠区间合并', () {
      final merged = mergeFocusSegments([
        FocusSegment(start: t(0), end: t(30)),
        FocusSegment(start: t(20), end: t(50)),
      ]);
      expect(merged, hasLength(1));
      expect(merged.first.ms, 50 * 1000);
    });

    test('相邻区间合并，分离区间保留', () {
      final merged = mergeFocusSegments([
        FocusSegment(start: t(0), end: t(10)),
        FocusSegment(start: t(10), end: t(20)),
        FocusSegment(start: t(30), end: t(40)),
      ]);
      expect(merged, hasLength(2));
    });

    test('乱序输入正确处理', () {
      final merged = mergeFocusSegments([
        FocusSegment(start: t(30), end: t(40)),
        FocusSegment(start: t(0), end: t(25)),
      ]);
      expect(merged, hasLength(2));
      expect(totalFocusMs(merged), 35 * 1000);
    });
  });

  test('totalFocusMs 去重后求和', () {
    final ms = totalFocusMs([
      FocusSegment(start: t(0), end: t(60)),
      FocusSegment(start: t(30), end: t(90)),
    ]);
    expect(ms, 90 * 1000);
  });

  test('totalDistractionMs = 总时长 - 专注时长', () {
    final distraction = totalDistractionMs(
      sessionStart: t(0),
      sessionEnd: t(100),
      focusSegments: [
        FocusSegment(start: t(0), end: t(40)),
        FocusSegment(start: t(60), end: t(100)),
      ],
    );
    expect(distraction, 20 * 1000);
  });

  test('专注时长不会超过会话总时长（钳制）', () {
    final distraction = totalDistractionMs(
      sessionStart: t(0),
      sessionEnd: t(10),
      focusSegments: [FocusSegment(start: t(0), end: t(50))],
    );
    expect(distraction, 0);
  });
}
