import 'package:ai_study_growth/src/core/di/providers.dart';
import 'package:ai_study_growth/src/data/local/app_database.dart';
import 'package:ai_study_growth/src/design_system/growth_theme.dart';
import 'package:ai_study_growth/src/features/home/presentation/main_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 白屏回归冒烟：主壳 + 三 Tab 必须能真实渲染（v0.10 白屏根因=导航栏越界）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = openAppDatabaseMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider
              .overrideWithValue(await SharedPreferences.getInstance()),
        ],
        child: const MaterialApp(
          home: MainShellPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('主壳渲染：dock 三项 + 相机键都在', (tester) async {
    await pumpShell(tester);

    expect(find.byType(MainShellPage), findsOneWidget);
    // 错题本：页栏标题 + dock 标签各一
    expect(find.text('错题本'), findsNWidgets(2));
    expect(find.text('复习'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切到复习 Tab 不崩', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('复习'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
