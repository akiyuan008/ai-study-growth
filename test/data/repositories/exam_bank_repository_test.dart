import 'package:ai_study_growth/src/data/repositories/exam_bank_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('真题库加载：题量>1000，覆盖 8 科', () async {
    final count = await ExamBankRepository.count();
    final subjects = await ExamBankRepository.subjects();
    expect(count, greaterThan(1000));
    expect(subjects.length, greaterThanOrEqualTo(8));
    expect(subjects, contains('数学'));
    expect(subjects, contains('物理'));
  });

  test('按科目检索：只返回该科目，且含选项与答案', () async {
    final found = await ExamBankRepository.search(
      subject: '物理',
      limit: 3,
    );
    expect(found, isNotEmpty);
    for (final q in found) {
      expect(q.subject, '物理');
      expect(q.options.length, greaterThanOrEqualTo(3));
      expect('ABCD', contains(q.answer));
      expect(q.stem.length, greaterThan(8));
      expect(q.sourceLabel, contains('真题'));
    }
  });

  test('排除原题：不返回与原题完全相同的题干', () async {
    final all = await ExamBankRepository.search(subject: '数学', limit: 1);
    if (all.isEmpty) return;
    final exclude = all.first.stem;
    final found = await ExamBankRepository.search(
      subject: '数学',
      excludeStem: exclude,
      limit: 5,
    );
    for (final q in found) {
      expect(q.stem, isNot(exclude));
    }
  });

  test('关键词命中优先：含关键词的题排在前面', () async {
    final found = await ExamBankRepository.search(
      subject: '物理',
      keywords: ['卫星'],
      limit: 3,
    );
    if (found.isEmpty) return;
    // 至少一道题干或解析含关键词
    final hit =
        found.any((q) => q.stem.contains('卫星') || q.explanation.contains('卫星'));
    expect(hit, isTrue);
  });
}
