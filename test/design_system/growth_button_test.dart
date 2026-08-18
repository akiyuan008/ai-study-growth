import 'package:ai_study_growth/src/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: buildGrowthTheme(Brightness.light),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('primary 按钮点击回调生效', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(
      GrowthButton(label: '开始专注', onPressed: () => tapped++),
    ));

    await tester.tap(find.text('开始专注'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('loading 状态屏蔽点击', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(
      GrowthButton(
        label: '解析中',
        loading: true,
        onPressed: () => tapped++,
      ),
    ));

    // loading 时文字隐藏、只显示进度环
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('解析中'), findsNothing);

    await tester.tap(find.byType(GrowthButton));
    await tester.pump();
    expect(tapped, 0);
  });

  testWidgets('onPressed 为 null 时按钮禁用', (tester) async {
    await tester.pumpWidget(_host(const GrowthButton(label: '禁用')));
    final inkwell = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(GrowthButton),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkwell.onTap, isNull);
  });

  testWidgets('图标与文字同时渲染', (tester) async {
    await tester.pumpWidget(_host(
      GrowthButton(
        label: '拍题',
        icon: Icons.camera_alt_rounded,
        onPressed: () {},
      ),
    ));
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    expect(find.text('拍题'), findsOneWidget);
  });
}
