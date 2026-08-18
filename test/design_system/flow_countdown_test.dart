import 'package:ai_study_growth/src/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: buildGrowthTheme(Brightness.dark),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('倒计时随时间推进并最终触发 onFinished', (tester) async {
    var finished = 0;
    await tester.pumpWidget(_host(
      FlowCountdown(
        total: const Duration(seconds: 2),
        onFinished: () => finished++,
      ),
    ));

    expect(find.text('00:02'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('00:01'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(finished, 1);

    // 完成后再走时间不重复触发
    await tester.pump(const Duration(seconds: 1));
    expect(finished, 1);
  });

  testWidgets('暂停后时间不再流逝，继续后恢复', (tester) async {
    await tester.pumpWidget(_host(
      FlowCountdown(
        total: const Duration(seconds: 10),
        onFinished: () {},
      ),
    ));

    await tester.tap(find.text('暂停'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    // 暂停期间显示不应变化
    expect(find.text('00:10'), findsOneWidget);

    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('00:09'), findsOneWidget);
  });

  testWidgets('结束按钮触发 onLeave', (tester) async {
    var left = 0;
    await tester.pumpWidget(_host(
      FlowCountdown(
        total: const Duration(seconds: 10),
        onFinished: () {},
        onLeave: () => left++,
      ),
    ));

    await tester.tap(find.text('结束'));
    await tester.pump();
    expect(left, 1);
  });
}
