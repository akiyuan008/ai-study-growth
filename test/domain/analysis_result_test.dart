import 'package:ai_study_growth/src/domain/models/analysis_result.dart';
import 'package:ai_study_growth/src/domain/models/generated_exercise.dart';
import 'package:ai_study_growth/src/domain/models/subject.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractJsonObject 容错', () {
    test('纯 JSON 直接解析', () {
      final json = extractJsonObject('{"a": 1}');
      expect(json?['a'], 1);
    });

    test('剥掉 markdown 围栏', () {
      final json = extractJsonObject('```json\n{"a": 2}\n```');
      expect(json?['a'], 2);
    });

    test('容忍前后噪声文本', () {
      final json = extractJsonObject('好的，结果如下：{"a": 3} 希望有帮助');
      expect(json?['a'], 3);
    });

    test('修复尾逗号', () {
      final json = extractJsonObject('{"a": 4, "b": [1, 2,],}');
      expect(json?['a'], 4);
      expect(json?['b'], [1, 2]);
    });

    test('无效内容返回 null', () {
      expect(extractJsonObject('没有任何 JSON'), isNull);
      expect(extractJsonObject(''), isNull);
    });
  });

  group('AnalysisResult.fromJson', () {
    test('完整字段解析', () {
      final r = AnalysisResult.fromJson({
        'subject': '物理',
        'reconstructedQuestionText': '一个物体自由下落…',
        'finalAnswer': '4.9m',
        'steps': ['步骤1', '步骤2'],
        'aiTags': ['力学', '自由落体'],
        'knowledgePoints': ['自由落体公式'],
        'mistakeReason': '忽略初速度',
        'studyAdvice': '多练运动学',
      });
      expect(r.subject, Subject.physics);
      expect(r.stem, contains('自由下落'));
      expect(r.finalAnswer, '4.9m');
      expect(r.steps, hasLength(2));
      expect(r.tags, ['力学', '自由落体']);
      expect(r.mistakeReason, '忽略初速度');
    });

    test('缺失字段给默认值，未知科目归为其他', () {
      final r = AnalysisResult.fromJson({'subject': '量子玄学'});
      expect(r.subject, Subject.other);
      expect(r.stem, '');
      expect(r.steps, isEmpty);
    });

    test('encode/decode 往返一致', () {
      final r = AnalysisResult.fromJson({
        'subject': '数学',
        'reconstructedQuestionText': '求解 x',
        'finalAnswer': 'x=2',
        'steps': ['移项'],
        'aiTags': ['方程'],
        'knowledgePoints': ['一元一次方程'],
        'mistakeReason': '计算失误',
      });
      final back = AnalysisResult.decode(r.encode());
      expect(back.stem, r.stem);
      expect(back.tags, r.tags);
    });
  });

  group('parseExercises', () {
    test('解析练习题列表', () {
      final items = parseExercises('''
{
  "generatedExercises": [
    {"difficulty": "简单", "question": "1+1=?", "options": ["A. 1", "B. 2"], "answer": "B", "explanation": "加法"},
    {"difficulty": "", "question": "", "options": [], "answer": "", "explanation": ""}
  ]
}''');
      expect(items, hasLength(1));
      expect(items.first.answer, 'B');
    });

    test('空内容返回空列表', () {
      expect(parseExercises('生成失败'), isEmpty);
      expect(parseExercises(''), isEmpty);
    });
  });

  group('CandidateAnalysis 序列化', () {
    test('带结果与错误的往返', () {
      final c = CandidateAnalysis(
        index: 2,
        status: CandidateStatus.failed,
        error: '超时',
      );
      final back = CandidateAnalysis.fromJson(c.toJson());
      expect(back.index, 2);
      expect(back.status, CandidateStatus.failed);
      expect(back.error, '超时');
    });
  });
}
