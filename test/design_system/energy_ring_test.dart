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
  const arcs = [
    AbilityArc(label: '学习', value: 0.7, color: GrowthColors.abilityLearning),
    AbilityArc(label: '专注', value: 0.5, color: GrowthColors.abilityFocus),
    AbilityArc(label: '坚持', value: 0.9, color: GrowthColors.abilityPersistence),
    AbilityArc(label: '恢复', value: 0.2, color: GrowthColors.abilityRecovery),
  ];

  testWidgets('四段弧正常渲染', (tester) async {
    await tester.pumpWidget(_host(const EnergyRing(arcs: arcs)));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(EnergyRing), findsOneWidget);
  });

  testWidgets('默认中心显示定性描述而非分数', (tester) async {
    await tester.pumpWidget(_host(const EnergyRing(arcs: arcs)));
    await tester.pumpAndSettle();
    // 均值 0.575 → 稳步成长；且不应出现任何百分数
    expect(find.text('稳步成长'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('能力值全部很低时提示等待发芽', (tester) async {
    const low = [
      AbilityArc(label: '学习', value: 0.05, color: GrowthColors.abilityLearning),
      AbilityArc(label: '专注', value: 0.1, color: GrowthColors.abilityFocus),
    ];
    await tester.pumpWidget(_host(const EnergyRing(arcs: low)));
    await tester.pumpAndSettle();
    expect(find.text('等待发芽'), findsOneWidget);
  });

  testWidgets('支持自定义中心组件', (tester) async {
    await tester.pumpWidget(_host(
      const EnergyRing(
        arcs: arcs,
        centerWidget: Text('自定义中心'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('自定义中心'), findsOneWidget);
  });
}
