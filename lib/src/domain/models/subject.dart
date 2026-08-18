/// 科目枚举（AI 自动判断 + 用户可改）
enum Subject {
  math('数学'),
  chinese('语文'),
  english('英语'),
  physics('物理'),
  chemistry('化学'),
  biology('生物'),
  history('历史'),
  geography('地理'),
  politics('政治'),
  other('其他');

  const Subject(this.label);

  final String label;

  static Subject fromName(String? name) {
    if (name == null || name.isEmpty) return Subject.other;
    for (final s in Subject.values) {
      if (s.name == name || s.label == name.trim()) return s;
    }
    return Subject.other;
  }
}
