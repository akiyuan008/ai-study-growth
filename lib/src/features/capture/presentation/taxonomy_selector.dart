import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../design_system/design_system.dart';

/// 层级知识点树模型（内置数据集 high_school_taxonomy.json，带版本号可更新）
class TaxonomyChapter {
  const TaxonomyChapter({required this.name, this.points = const []});

  final String name;
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
    for (final s in (json['subjects'] as List)) {
      final sMap = s as Map<String, dynamic>;
      final versions = <TaxonomyVersion>[];
      for (final v in (sMap['versions'] as List)) {
        final vMap = v as Map<String, dynamic>;
        final books = <TaxonomyBook>[];
        for (final b in (vMap['books'] as List)) {
          final bMap = b as Map<String, dynamic>;
          final chapters = <TaxonomyChapter>[];
          for (final c in (bMap['chapters'] as List)) {
            final cMap = c as Map<String, dynamic>;
            chapters.add(TaxonomyChapter(
              name: (cMap['name'] ?? '').toString(),
              points: ((cMap['points'] as List?) ?? const [])
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
            name: (vMap['name'] ?? '').toString(), books: books));
      }
      subjects.add(TaxonomySubject(
          name: (sMap['name'] ?? '').toString(), versions: versions));
    }
    final taxonomy = Taxonomy(
      version: (json['version'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      subjects: subjects,
    );
    _cache = taxonomy;
    return taxonomy;
  }
}

/// 级联选择结果
class TaxonomySelection {
  const TaxonomySelection({
    this.subject = '',
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

  /// 知识点（支持多选 + 自定义）
  final List<String> points;

  String get breadcrumb => [
        subject,
        version,
        book,
        chapter,
        lesson,
        points.join('、'),
      ].where((s) => s.isNotEmpty).join(' · ');
}

/// 级联选择器（v14：学科→版本→册→章→节→知识点）。
/// 每级历史值置顶、每级含「自定义」兜底、知识点支持多选。
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
  final Set<String> _points = {};

  /// 历史值缓存（每级）
  final Map<String, List<String>> _history = {};

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
    _load();
  }

  Future<void> _load() async {
    final taxonomy = await Taxonomy.load();
    await _loadHistory();
    if (mounted) setState(() => _taxonomy = taxonomy);
  }

  Future<void> _loadHistory() async {
    final db = ref.read(databaseProvider);
    final rows = await (db.select(db.knowledgePoints)..limit(300)).get();
    _history['version'] =
        _distinct(rows.map((r) => r.version).where((s) => s.isNotEmpty));
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

  void _confirm() {
    widget.onConfirm(TaxonomySelection(
      subject: _subject,
      version: _version,
      book: _book,
      chapter: _chapter,
      points: _points.toList(),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final taxonomy = _taxonomy;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
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
                          _version = '';
                          _book = '';
                          _chapter = '';
                          _points.clear();
                        }),
                      ),
                      if (_subjectObj != null) ...[
                        _levelTitle('教材版本'),
                        _chips(
                          options:
                              _subjectObj!.versions.map((v) => v.name).toList(),
                          history: _history['version'] ?? const [],
                          selected: {_version},
                          onPick: (v) => setState(() {
                            _version = v;
                            _book = '';
                            _chapter = '';
                            _points.clear();
                          }),
                        ),
                      ],
                      if (_versionObj != null) ...[
                        _levelTitle('册别'),
                        _chips(
                          options:
                              _versionObj!.books.map((b) => b.name).toList(),
                          history: _history['book'] ?? const [],
                          selected: {_book},
                          onPick: (v) => setState(() {
                            _book = v;
                            _chapter = '';
                            _points.clear();
                          }),
                        ),
                      ],
                      if (_bookObj != null) ...[
                        _levelTitle('章（宁浅勿造：无目录的册可跳过）'),
                        _chips(
                          options:
                              _bookObj!.chapters.map((c) => c.name).toList(),
                          history: _history['chapter'] ?? const [],
                          selected: {_chapter},
                          allowCustom: true,
                          onPick: (v) => setState(() {
                            _chapter = v;
                            _points.clear();
                          }),
                          onCustom: (v) => setState(() {
                            _chapter = v;
                            _points.clear();
                          }),
                        ),
                      ],
                      // 知识点：建议列表 + 多选 + 自定义
                      _levelTitle('知识点（可多选）'),
                      _chips(
                        options: _chapterObj?.points ?? const [],
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
            color: GrowthColors.gray5,
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
