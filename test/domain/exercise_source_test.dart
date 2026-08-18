import 'package:ai_study_growth/src/domain/models/generated_exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseItem 来源映射（Part 3.4）', () {
    test('AI cited + 出处 → L2 真题引用标签', () {
      final item = ExerciseItem.fromJson({
        'difficulty': '简单',
        'question': '题目',
        'options': ['A. 1', 'B. 2'],
        'answer': 'A',
        'explanation': '解析',
        'sourceStatus': 'cited',
        'source': {'year': '2023', 'region': '全国', 'examName': '甲卷'},
      });
      expect(item.sourceLevel, ExerciseSourceLevel.l2Cited);
      expect(item.displaySourceLabel, contains('2023'));
      expect(item.displaySourceLabel, contains('甲卷'));
    });

    test('uncertain → L3 来源待核实', () {
      final item = ExerciseItem.fromJson({
        'question': '题目',
        'answer': 'B',
        'sourceStatus': 'uncertain',
      });
      expect(item.sourceLevel, ExerciseSourceLevel.l3Unverified);
      expect(item.displaySourceLabel, '来源待核实');
    });

    test('无 sourceStatus → L4 AI 拟题', () {
      final item = ExerciseItem.fromJson({
        'question': '题目',
        'answer': 'C',
      });
      expect(item.sourceLevel, ExerciseSourceLevel.l4Generated);
      expect(item.displaySourceLabel, 'AI 拟题');
    });

    test('L1 内部格式往返保留 bankId 与标签', () {
      const original = ExerciseItem(
        difficulty: '真题',
        question: '库内题',
        options: [],
        answer: 'D',
        explanation: '',
        sourceLevel: ExerciseSourceLevel.l1Personal,
        sourceLabel: '真题 · 来自你的题库',
        bankId: 'bank-1',
      );
      final back = ExerciseItem.fromJson(original.toJson());
      expect(back.sourceLevel, ExerciseSourceLevel.l1Personal);
      expect(back.bankId, 'bank-1');
      expect(back.displaySourceLabel, '真题 · 来自你的题库');
    });
  });
}
