import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../design_system/design_system.dart';

/// 层级知识点树模型（内置数据集 high_school_taxonomy.json，带版本号可更新）
///
/// 级联：学科 → 册 → 章 → 节（数据集未收录时自动省略）→ 知识点
class TaxonomyLesson {
  const TaxonomyLesson({required this.name, this.points = const []});

  final String name;
  final List<String> points;
}

class TaxonomyChapter {
  const TaxonomyChapter({
    required this.name,
    this.lessons = const [],
    this.points = const [],
  });

  final String name;

  /// 节级（数据集收录时展示，未收录自动省略）
  final List<TaxonomyLesson> lessons;

  /// 章直挂知识点（无节级时使用）
  final List<String> points;
}

class TaxonomyBook {
  const TaxonomyBook({required this.name, this.chapters = const []});

  final String name;
  final List<TaxonomyChapter> chapters;
}

class TaxonomyVersion {
  const TaxonomyVersion({required this.name, this.books = const []});

  final String name;
  final List<TaxonomyBook> books;
}

class TaxonomySubject {
  const TaxonomySubject({required this.name, this.versions = const []});

  final String name;
  final List<TaxonomyVersion> versions;
}

class Taxonomy {
  const Taxonomy({
    required this.version,
    required this.note,
    required this.subjects,
  });

  final String version;
  final String note;
  final List<TaxonomySubject> subjects;

  static Taxonomy? _cache;

  static Future<Taxonomy> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle
        .loadString('assets/taxonomy/high_school_taxonomy.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final subjects = <TaxonomySubject>[];
    for (final sEntry in (json['subjects'] as List)) {
      final sMap = sEntry as Map<String, dynamic>;
      final versions = <TaxonomyVersion>[];
      for (final v in (sMap['versions'] as List)) {
        final vMap = v as Map<String, dynamic>;
        final books = <TaxonomyBook>[];
        for (final b in (vMap['books'] as List)) {
          final bMap = b as Map<String, dynamic>;
          final chapters = <TaxonomyChapter>[];
          for (final c in (bMap['chapters'] as List? ?? const [])) {
            final cMap = c as Map<String, dynamic>;
            final lessons = <TaxonomyLesson>[];
            for (final l in (cMap['lessons'] as List? ?? const [])) {
              final lMap = l as Map<String, dynamic>;
              lessons.add(TaxonomyLesson(
                name: (lMap['name'] ?? '').toString(),
                points: (lMap['points'] as List? ?? const [])
                    .map((e) => e.toString())
                    .toList(),
              ));
            }
            chapters.add(TaxonomyChapter(
              name: (cMap['name'] ?? '').toString(),
              lessons: lessons,
              points: (cMap['points'] as List? ?? const [])
                  .map((e) => e.toString())
                  .toList(),
            ));
          }
          books.add(TaxonomyBook(
            name: (bMap['name'] ?? '').toString(),
            chapters: chapters,
          ));
        }
        versions.add(TaxonomyVersion(
          name: (vMap['name'] ?? '').toString(),
          books: books,
        ));
      }
      subjects.add(TaxonomySubject(
        name: (sMap['name'] ?? '').toString(),
        versions: versions,
      ));
    }
    _cache = Taxonomy(
      version: (json['version'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      subjects: subjects,
    );
    return _cache!;
  }
}

/// 级联选择结果
class TaxonomySelection {
  const TaxonomySelection({
    required this.subject,
    this.version = '',
    this.book = '',
    this.chapter = '',
    this.lesson = '',
    this.points = const [],
  });

  final String subject;
  final String version;
  final String book;
  final String chapter;
  final String lesson;
  final List<String> points;

  String get breadcrumb => [subject, book, chapter, lesson, ...points]
      .where((s) => s.isNotEmpty)
      .join(' · ');
}

/// 知识点级联选择器（终版）：
/// 学科 → 册 → 章 → 节 → 知识点，人教 2023 目录；
/// 搜索框全局检索知识点；每级历史值置顶 + 自定义兜底。
class TaxonomySelectorSheet extends ConsumerStatefulWidget {
  const TaxonomySelectorSheet({
    super.key,
    required this.initialSubject,
    required this.onConfirm,
  });

  final String initialSubject;
  final ValueChanged<TaxonomySelection> onConfirm;

  @override
  ConsumerState<TaxonomySelectorSheet> createState() =>
      _TaxonomySelectorSheetState();
}

class _TaxonomySelectorSheetState extends ConsumerState<TaxonomySelectorSheet> {
  Taxonomy? _taxonomy;

  String _subject = '';
  String _version = '';
  String _book = '';
  String _chapter = '';
  String _lesson = '';
  final Set<String> _points = {};

  /// 知识点搜索
  final _searchController = TextEditingController();
  String _searchText = '';

  /// 历史值缓存（每级）
  final Map<String, List<String>> _history = {};

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final taxonomy = await Taxonomy.load();
    await _loadHistory();
    if (!mounted) return;
    setState(() {
      _taxonomy = taxonomy;
      // 版本级不进 UI：固定取该学科第一个版本（人教版）
      _version = _subjectObj?.versions.firstOrNull?.name ?? '';
    });
  }

  Future<void> _loadHistory() async {
    final db = ref.read(databaseProvider);
    final rows = await (db.select(db.knowledgePoints)..limit(300)).get();
    _history['book'] =
        _distinct(rows.map((r) => r.book).where((s) => s.isNotEmpty));
    _history['chapter'] =
        _distinct(rows.map((r) => r.chapter).where((s) => s.isNotEmpty));
    _history['lesson'] =
        _distinct(rows.map((r) => r.lesson).where((s) => s.isNotEmpty));
    _history['point'] =
        _distinct(rows.where((r) => r.subject == _subject).map((r) => r.name));
  }

  List<String> _distinct(Iterable<String> values) {
    final seen = <String>{};
    return values.where(seen.add).take(6).toList();
  }

  TaxonomySubject? get _subjectObj =>
      _taxonomy?.subjects.where((s) => s.name == _subject).firstOrNull;

  TaxonomyVersion? get _versionObj =>
      _subjectObj?.versions.where((v) => v.name == _version).firstOrNull;

  TaxonomyBook? get _bookObj =>
      _versionObj?.books.where((b) => b.name == _book).firstOrNull;

  TaxonomyChapter? get _chapterObj =>
      _bookObj?.chapters.where((c) => c.name == _chapter).firstOrNull;

  TaxonomyLesson? get _lessonObj =>
      _chapterObj?.lessons.where((l) => l.name == _lesson).firstOrNull;

  /// 当前知识点候选：有节级取节下，否则取章直挂
  List<String> get _pointOptions => _chapterObj == null
      ? const []
      : (_chapterObj!.lessons.isNotEmpty
          ? (_lessonObj?.points ?? const [])
          : _chapterObj!.points);

  /// 搜索结果：学科内跨册/章/节匹配知识点
  List<({String book, String chapter, String lesson, String point})>
      get _searchResults {
    final q = _searchText.trim();
    if (q.isEmpty || _versionObj == null) return const [];
    final results =
        <({String book, String chapter, String lesson, String point})>[];
    for (final book in _versionObj!.books) {
      for (final chapter in book.chapters) {
        if (chapter.lessons.isNotEmpty) {
          for (final lesson in chapter.lessons) {
            for (final point in lesson.points) {
              if (point.contains(q) ||
                  lesson.name.contains(q) ||
                  chapter.name.contains(q)) {
                results.add((
                  book: book.name,
                  chapter: chapter.name,
                  lesson: lesson.name,
                  point: point,
                ));
              }
            }
          }
        } else {
          for (final point in chapter.points) {
            if (point.contains(q) || chapter.name.contains(q)) {
              results.add((
                book: book.name,
                chapter: chapter.name,
                lesson: '',
                point: point,
              ));
            }
          }
        }
      }
    }
    return results.take(20).toList();
  }

  void _confirm() {
    widget.onConfirm(TaxonomySelection(
      subject: _subject,
      version: _version,
      book: _book,
      chapter: _chapter,
      lesson: _lesson,
      points: _points.toList(),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final taxonomy = _taxonomy;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: taxonomy == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('知识点层级', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: GrowthSpacing.xs),
                Text(
                  taxonomy.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: GrowthSpacing.sm),
                // 已选面包屑
                if (_breadcrumb.isNotEmpty) ...[
                  Text(
                    _breadcrumb,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: GrowthColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GrowthSpacing.sm),
                ],
                Expanded(
                  child: ListView(
                    children: [
                      _levelTitle('学科'),
                      _chips(
                        options: taxonomy.subjects.map((s) => s.name).toList(),
                        history: const [],
                        selected: {_subject},
                        onPick: (v) => setState(() {
                          _subject = v;
                          _version =
                              _subjectObj?.versions.firstOrNull?.name ?? '';
                          _book = '';
                          _chapter = '';
                          _lesson = '';
                          _points.clear();
                        }),
                      ),
                      if (_versionObj != null) ...[
                        _levelTitle('册'),
                        _chips(
                          options:
                              _versionObj!.books.map((b) => b.name).toList(),
                          history: _history['book'] ?? const [],
                          selected: {_book},
                          onPick: (v) => setState(() {
                            _book = v;
                            _chapter = '';
                            _lesson = '';
                            _points.clear();
                          }),
                        ),
                      ],
                      if (_bookObj != null) ...[
                        _levelTitle('章'),
                        _chips(
                          options:
                              _bookObj!.chapters.map((c) => c.name).toList(),
                          history: _history['chapter'] ?? const [],
                          selected: {_chapter},
                          allowCustom: true,
                          onPick: (v) => setState(() {
                            _chapter = v;
                            _lesson = '';
                            _points.clear();
                          }),
                          onCustom: (v) => setState(() {
                            _chapter = v;
                            _lesson = '';
                            _points.clear();
                          }),
                        ),
                      ],
                      // 节级：数据集收录时展示
                      if (_chapterObj != null &&
                          _chapterObj!.lessons.isNotEmpty) ...[
                        _levelTitle('节'),
                        _chips(
                          options:
                              _chapterObj!.lessons.map((l) => l.name).toList(),
                          history: _history['lesson'] ?? const [],
                          selected: {_lesson},
                          allowCustom: true,
                          onPick: (v) => setState(() {
                            _lesson = v;
                            _points.clear();
                          }),
                          onCustom: (v) => setState(() {
                            _lesson = v;
                            _points.clear();
                          }),
                        ),
                      ],
                      // 知识点：建议列表 + 多选 + 自定义
                      _levelTitle('知识点（可多选）'),
                      _chips(
                        options: _pointOptions,
                        history: _history['point'] ?? const [],
                        selected: _points,
                        multi: true,
                        allowCustom: true,
                        onPick: (v) => setState(() {
                          if (_points.contains(v)) {
                            _points.remove(v);
                          } else {
                            _points.add(v);
                          }
                        }),
                        onCustom: (v) => setState(() => _points.add(v)),
                      ),
                      // 搜索框：学科内全局检索知识点
                      if (_subject.isNotEmpty) ...[
                        _levelTitle('搜索知识点'),
                        GrowthTextField(
                          controller: _searchController,
                          hint: '输入知识点 / 章节名检索',
                          onChanged: (v) => setState(() => _searchText = v),
                        ),
                        const SizedBox(height: GrowthSpacing.xs),
                        for (final r in _searchResults)
                          InkWell(
                            onTap: () => setState(() {
                              _book = r.book;
                              _chapter = r.chapter;
                              _lesson = r.lesson;
                              _points.add(r.point);
                              _searchController.clear();
                              _searchText = '';
                            }),
                            borderRadius:
                                BorderRadius.circular(GrowthRadii.icon),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: GrowthSpacing.xs),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded,
                                      size: 16, color: GrowthColors.gray4),
                                  const SizedBox(width: GrowthSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      '${r.book} · ${r.chapter}'
                                      '${r.lesson.isNotEmpty ? ' · ${r.lesson}' : ''}'
                                      ' · ${r.point}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  if (_points.contains(r.point))
                                    const Icon(Icons.check_circle_rounded,
                                        size: 16, color: GrowthColors.primary),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                GrowthButton(
                  label: '确定',
                  expanded: true,
                  onPressed:
                      (_subject.isEmpty && _points.isEmpty) ? null : _confirm,
                ),
              ],
            ),
    );
  }

  String get _breadcrumb => TaxonomySelection(
        subject: _subject,
        version: _version,
        book: _book,
        chapter: _chapter,
        lesson: _lesson,
        points: _points.toList(),
      ).breadcrumb;

  Widget _levelTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: GrowthSpacing.sm,
        bottom: GrowthSpacing.xs,
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _chips({
    required List<String> options,
    required List<String> history,
    required Set<String> selected,
    bool multi = false,
    bool allowCustom = false,
    required ValueChanged<String> onPick,
    ValueChanged<String>? onCustom,
  }) {
    // 历史值置顶，去重
    final merged = <String>[
      ...history.where((h) => options.contains(h)),
      ...options.where((o) => !history.contains(o)),
      ...history.where((h) => !options.contains(h)),
    ];
    return Wrap(
      spacing: GrowthSpacing.xs,
      runSpacing: GrowthSpacing.xs,
      children: [
        for (final option in merged)
          GrowthChip(
            label: option,
            selected: selected.contains(option),
            onTap: () => onPick(option),
          ),
        if (allowCustom)
          GrowthChip(
            label: '＋ 自定义',
            color: GrowthColors.muted(
                Theme.of(context).brightness == Brightness.light),
            onTap: () => _openCustomInput(onCustom ?? onPick),
          ),
      ],
    );
  }

  void _openCustomInput(ValueChanged<String> onSubmit) {
    final controller = TextEditingController();
    showGrowthSheet<void>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GrowthTextField(
            controller: controller,
            hint: '输入自定义内容',
            onSubmitted: (_) {},
          ),
          const SizedBox(height: GrowthSpacing.md),
          GrowthButton(
            label: '添加',
            expanded: true,
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) onSubmit(v);
              Navigator.of(sheetContext).pop();
            },
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
