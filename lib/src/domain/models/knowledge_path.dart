/// 层级知识点路径（Part 3.2 硬门 3）：
/// subject → version → book → chapter → lesson → point
class KnowledgePath {
  const KnowledgePath({
    this.subject = '',
    this.version = '',
    this.book = '',
    this.chapter = '',
    this.lesson = '',
    this.point = '',
  });

  final String subject;

  /// 教材版本（可推断必须可改）
  final String version;
  final String book;
  final String chapter;
  final String lesson;

  /// 最末级知识点
  final String point;

  bool get isEmpty =>
      subject.isEmpty &&
      version.isEmpty &&
      book.isEmpty &&
      chapter.isEmpty &&
      lesson.isEmpty &&
      point.isEmpty;

  /// 面包屑：非空层级拼接
  String get breadcrumb {
    final parts = [subject, version, book, chapter, lesson, point]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.join(' · ');
  }

  /// 最具体的非空层级作为知识点名称
  String get leafName =>
      point.isNotEmpty ? point : (breadcrumb.split(' · ').lastOrNull ?? '');

  KnowledgePath copyWith({
    String? subject,
    String? version,
    String? book,
    String? chapter,
    String? lesson,
    String? point,
  }) =>
      KnowledgePath(
        subject: subject ?? this.subject,
        version: version ?? this.version,
        book: book ?? this.book,
        chapter: chapter ?? this.chapter,
        lesson: lesson ?? this.lesson,
        point: point ?? this.point,
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'version': version,
        'book': book,
        'chapter': chapter,
        'lesson': lesson,
        'point': point,
      };

  /// 容错解析（AI 输出 + 正则兜底由调用方 extractJsonObject 处理）
  factory KnowledgePath.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] ?? '').toString().trim();
    return KnowledgePath(
      subject: read('subject'),
      version: read('version'),
      book: read('book'),
      chapter: read('chapter'),
      lesson: read('lesson'),
      point: read('point').isNotEmpty
          ? read('point')
          : read('knowledgePoint').isNotEmpty
              ? read('knowledgePoint')
              : read('name'),
    );
  }
}
