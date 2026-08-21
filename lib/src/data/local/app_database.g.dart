// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $QuestionRecordsTable extends QuestionRecords
    with TableInfo<$QuestionRecordsTable, QuestionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stemMeta = const VerificationMeta('stem');
  @override
  late final GeneratedColumn<String> stem = GeneratedColumn<String>(
      'stem', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
      'answer', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _keyStepsMeta =
      const VerificationMeta('keySteps');
  @override
  late final GeneratedColumn<String> keySteps = GeneratedColumn<String>(
      'key_steps', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorCauseMeta =
      const VerificationMeta('errorCause');
  @override
  late final GeneratedColumn<String> errorCause = GeneratedColumn<String>(
      'error_cause', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _analysisDetailMeta =
      const VerificationMeta('analysisDetail');
  @override
  late final GeneratedColumn<String> analysisDetail = GeneratedColumn<String>(
      'analysis_detail', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('capture'));
  static const VerificationMeta _contentStatusMeta =
      const VerificationMeta('contentStatus');
  @override
  late final GeneratedColumn<String> contentStatus = GeneratedColumn<String>(
      'content_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _masteryLevelMeta =
      const VerificationMeta('masteryLevel');
  @override
  late final GeneratedColumn<int> masteryLevel = GeneratedColumn<int>(
      'mastery_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        subject,
        imagePath,
        stem,
        answer,
        keySteps,
        errorCause,
        analysisDetail,
        tags,
        source,
        contentStatus,
        masteryLevel,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_records';
  @override
  VerificationContext validateIntegrity(Insertable<QuestionRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('stem')) {
      context.handle(
          _stemMeta, stem.isAcceptableOrUnknown(data['stem']!, _stemMeta));
    }
    if (data.containsKey('answer')) {
      context.handle(_answerMeta,
          answer.isAcceptableOrUnknown(data['answer']!, _answerMeta));
    }
    if (data.containsKey('key_steps')) {
      context.handle(_keyStepsMeta,
          keySteps.isAcceptableOrUnknown(data['key_steps']!, _keyStepsMeta));
    }
    if (data.containsKey('error_cause')) {
      context.handle(
          _errorCauseMeta,
          errorCause.isAcceptableOrUnknown(
              data['error_cause']!, _errorCauseMeta));
    }
    if (data.containsKey('analysis_detail')) {
      context.handle(
          _analysisDetailMeta,
          analysisDetail.isAcceptableOrUnknown(
              data['analysis_detail']!, _analysisDetailMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('content_status')) {
      context.handle(
          _contentStatusMeta,
          contentStatus.isAcceptableOrUnknown(
              data['content_status']!, _contentStatusMeta));
    }
    if (data.containsKey('mastery_level')) {
      context.handle(
          _masteryLevelMeta,
          masteryLevel.isAcceptableOrUnknown(
              data['mastery_level']!, _masteryLevelMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      stem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stem'])!,
      answer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer']),
      keySteps: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_steps']),
      errorCause: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_cause']),
      analysisDetail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}analysis_detail']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      contentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_status'])!,
      masteryLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mastery_level'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $QuestionRecordsTable createAlias(String alias) {
    return $QuestionRecordsTable(attachedDatabase, alias);
  }
}

class QuestionRecord extends DataClass implements Insertable<QuestionRecord> {
  /// uuid
  final String id;

  /// 科目（数学/物理/...）
  final String subject;

  /// 本地图片路径（题干照片）
  final String? imagePath;

  /// 题干
  final String stem;

  /// 答案
  final String? answer;

  /// 关键步骤
  final String? keySteps;

  /// 错因
  final String? errorCause;

  /// AI 解析详情（markdown）
  final String? analysisDetail;

  /// 短标签，JSON 数组字符串，如 ["压强","力学"]
  final String tags;

  /// 来源：capture / manual / import
  final String source;

  /// 状态：draft / saved / archived
  final String contentStatus;

  /// 掌握度 0-5（由复习/练习结果驱动，成长引擎读取）
  final int masteryLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  const QuestionRecord(
      {required this.id,
      required this.subject,
      this.imagePath,
      required this.stem,
      this.answer,
      this.keySteps,
      this.errorCause,
      this.analysisDetail,
      required this.tags,
      required this.source,
      required this.contentStatus,
      required this.masteryLevel,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject'] = Variable<String>(subject);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['stem'] = Variable<String>(stem);
    if (!nullToAbsent || answer != null) {
      map['answer'] = Variable<String>(answer);
    }
    if (!nullToAbsent || keySteps != null) {
      map['key_steps'] = Variable<String>(keySteps);
    }
    if (!nullToAbsent || errorCause != null) {
      map['error_cause'] = Variable<String>(errorCause);
    }
    if (!nullToAbsent || analysisDetail != null) {
      map['analysis_detail'] = Variable<String>(analysisDetail);
    }
    map['tags'] = Variable<String>(tags);
    map['source'] = Variable<String>(source);
    map['content_status'] = Variable<String>(contentStatus);
    map['mastery_level'] = Variable<int>(masteryLevel);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuestionRecordsCompanion toCompanion(bool nullToAbsent) {
    return QuestionRecordsCompanion(
      id: Value(id),
      subject: Value(subject),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      stem: Value(stem),
      answer:
          answer == null && nullToAbsent ? const Value.absent() : Value(answer),
      keySteps: keySteps == null && nullToAbsent
          ? const Value.absent()
          : Value(keySteps),
      errorCause: errorCause == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCause),
      analysisDetail: analysisDetail == null && nullToAbsent
          ? const Value.absent()
          : Value(analysisDetail),
      tags: Value(tags),
      source: Value(source),
      contentStatus: Value(contentStatus),
      masteryLevel: Value(masteryLevel),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuestionRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRecord(
      id: serializer.fromJson<String>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      stem: serializer.fromJson<String>(json['stem']),
      answer: serializer.fromJson<String?>(json['answer']),
      keySteps: serializer.fromJson<String?>(json['keySteps']),
      errorCause: serializer.fromJson<String?>(json['errorCause']),
      analysisDetail: serializer.fromJson<String?>(json['analysisDetail']),
      tags: serializer.fromJson<String>(json['tags']),
      source: serializer.fromJson<String>(json['source']),
      contentStatus: serializer.fromJson<String>(json['contentStatus']),
      masteryLevel: serializer.fromJson<int>(json['masteryLevel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subject': serializer.toJson<String>(subject),
      'imagePath': serializer.toJson<String?>(imagePath),
      'stem': serializer.toJson<String>(stem),
      'answer': serializer.toJson<String?>(answer),
      'keySteps': serializer.toJson<String?>(keySteps),
      'errorCause': serializer.toJson<String?>(errorCause),
      'analysisDetail': serializer.toJson<String?>(analysisDetail),
      'tags': serializer.toJson<String>(tags),
      'source': serializer.toJson<String>(source),
      'contentStatus': serializer.toJson<String>(contentStatus),
      'masteryLevel': serializer.toJson<int>(masteryLevel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuestionRecord copyWith(
          {String? id,
          String? subject,
          Value<String?> imagePath = const Value.absent(),
          String? stem,
          Value<String?> answer = const Value.absent(),
          Value<String?> keySteps = const Value.absent(),
          Value<String?> errorCause = const Value.absent(),
          Value<String?> analysisDetail = const Value.absent(),
          String? tags,
          String? source,
          String? contentStatus,
          int? masteryLevel,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      QuestionRecord(
        id: id ?? this.id,
        subject: subject ?? this.subject,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        stem: stem ?? this.stem,
        answer: answer.present ? answer.value : this.answer,
        keySteps: keySteps.present ? keySteps.value : this.keySteps,
        errorCause: errorCause.present ? errorCause.value : this.errorCause,
        analysisDetail:
            analysisDetail.present ? analysisDetail.value : this.analysisDetail,
        tags: tags ?? this.tags,
        source: source ?? this.source,
        contentStatus: contentStatus ?? this.contentStatus,
        masteryLevel: masteryLevel ?? this.masteryLevel,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  QuestionRecord copyWithCompanion(QuestionRecordsCompanion data) {
    return QuestionRecord(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      stem: data.stem.present ? data.stem.value : this.stem,
      answer: data.answer.present ? data.answer.value : this.answer,
      keySteps: data.keySteps.present ? data.keySteps.value : this.keySteps,
      errorCause:
          data.errorCause.present ? data.errorCause.value : this.errorCause,
      analysisDetail: data.analysisDetail.present
          ? data.analysisDetail.value
          : this.analysisDetail,
      tags: data.tags.present ? data.tags.value : this.tags,
      source: data.source.present ? data.source.value : this.source,
      contentStatus: data.contentStatus.present
          ? data.contentStatus.value
          : this.contentStatus,
      masteryLevel: data.masteryLevel.present
          ? data.masteryLevel.value
          : this.masteryLevel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRecord(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('imagePath: $imagePath, ')
          ..write('stem: $stem, ')
          ..write('answer: $answer, ')
          ..write('keySteps: $keySteps, ')
          ..write('errorCause: $errorCause, ')
          ..write('analysisDetail: $analysisDetail, ')
          ..write('tags: $tags, ')
          ..write('source: $source, ')
          ..write('contentStatus: $contentStatus, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      subject,
      imagePath,
      stem,
      answer,
      keySteps,
      errorCause,
      analysisDetail,
      tags,
      source,
      contentStatus,
      masteryLevel,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRecord &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.imagePath == this.imagePath &&
          other.stem == this.stem &&
          other.answer == this.answer &&
          other.keySteps == this.keySteps &&
          other.errorCause == this.errorCause &&
          other.analysisDetail == this.analysisDetail &&
          other.tags == this.tags &&
          other.source == this.source &&
          other.contentStatus == this.contentStatus &&
          other.masteryLevel == this.masteryLevel &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuestionRecordsCompanion extends UpdateCompanion<QuestionRecord> {
  final Value<String> id;
  final Value<String> subject;
  final Value<String?> imagePath;
  final Value<String> stem;
  final Value<String?> answer;
  final Value<String?> keySteps;
  final Value<String?> errorCause;
  final Value<String?> analysisDetail;
  final Value<String> tags;
  final Value<String> source;
  final Value<String> contentStatus;
  final Value<int> masteryLevel;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuestionRecordsCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.stem = const Value.absent(),
    this.answer = const Value.absent(),
    this.keySteps = const Value.absent(),
    this.errorCause = const Value.absent(),
    this.analysisDetail = const Value.absent(),
    this.tags = const Value.absent(),
    this.source = const Value.absent(),
    this.contentStatus = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionRecordsCompanion.insert({
    required String id,
    this.subject = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.stem = const Value.absent(),
    this.answer = const Value.absent(),
    this.keySteps = const Value.absent(),
    this.errorCause = const Value.absent(),
    this.analysisDetail = const Value.absent(),
    this.tags = const Value.absent(),
    this.source = const Value.absent(),
    this.contentStatus = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<QuestionRecord> custom({
    Expression<String>? id,
    Expression<String>? subject,
    Expression<String>? imagePath,
    Expression<String>? stem,
    Expression<String>? answer,
    Expression<String>? keySteps,
    Expression<String>? errorCause,
    Expression<String>? analysisDetail,
    Expression<String>? tags,
    Expression<String>? source,
    Expression<String>? contentStatus,
    Expression<int>? masteryLevel,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (imagePath != null) 'image_path': imagePath,
      if (stem != null) 'stem': stem,
      if (answer != null) 'answer': answer,
      if (keySteps != null) 'key_steps': keySteps,
      if (errorCause != null) 'error_cause': errorCause,
      if (analysisDetail != null) 'analysis_detail': analysisDetail,
      if (tags != null) 'tags': tags,
      if (source != null) 'source': source,
      if (contentStatus != null) 'content_status': contentStatus,
      if (masteryLevel != null) 'mastery_level': masteryLevel,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? subject,
      Value<String?>? imagePath,
      Value<String>? stem,
      Value<String?>? answer,
      Value<String?>? keySteps,
      Value<String?>? errorCause,
      Value<String?>? analysisDetail,
      Value<String>? tags,
      Value<String>? source,
      Value<String>? contentStatus,
      Value<int>? masteryLevel,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return QuestionRecordsCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      imagePath: imagePath ?? this.imagePath,
      stem: stem ?? this.stem,
      answer: answer ?? this.answer,
      keySteps: keySteps ?? this.keySteps,
      errorCause: errorCause ?? this.errorCause,
      analysisDetail: analysisDetail ?? this.analysisDetail,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      contentStatus: contentStatus ?? this.contentStatus,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (stem.present) {
      map['stem'] = Variable<String>(stem.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (keySteps.present) {
      map['key_steps'] = Variable<String>(keySteps.value);
    }
    if (errorCause.present) {
      map['error_cause'] = Variable<String>(errorCause.value);
    }
    if (analysisDetail.present) {
      map['analysis_detail'] = Variable<String>(analysisDetail.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (contentStatus.present) {
      map['content_status'] = Variable<String>(contentStatus.value);
    }
    if (masteryLevel.present) {
      map['mastery_level'] = Variable<int>(masteryLevel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('imagePath: $imagePath, ')
          ..write('stem: $stem, ')
          ..write('answer: $answer, ')
          ..write('keySteps: $keySteps, ')
          ..write('errorCause: $errorCause, ')
          ..write('analysisDetail: $analysisDetail, ')
          ..write('tags: $tags, ')
          ..write('source: $source, ')
          ..write('contentStatus: $contentStatus, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionBankTable extends QuestionBank
    with TableInfo<$QuestionBankTable, QuestionBankData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionBankTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceQuestionIdMeta =
      const VerificationMeta('sourceQuestionId');
  @override
  late final GeneratedColumn<String> sourceQuestionId = GeneratedColumn<String>(
      'source_question_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _knowledgePointIdMeta =
      const VerificationMeta('knowledgePointId');
  @override
  late final GeneratedColumn<String> knowledgePointId = GeneratedColumn<String>(
      'knowledge_point_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _questionTypeMeta =
      const VerificationMeta('questionType');
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
      'question_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('solve'));
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceLabelMeta =
      const VerificationMeta('sourceLabel');
  @override
  late final GeneratedColumn<String> sourceLabel = GeneratedColumn<String>(
      'source_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceCitationMeta =
      const VerificationMeta('sourceCitation');
  @override
  late final GeneratedColumn<String> sourceCitation = GeneratedColumn<String>(
      'source_citation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usedCountMeta =
      const VerificationMeta('usedCount');
  @override
  late final GeneratedColumn<int> usedCount = GeneratedColumn<int>(
      'used_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sourceQuestionId,
        knowledgePointId,
        subject,
        questionType,
        difficulty,
        content,
        kind,
        sourceLabel,
        sourceCitation,
        usedCount,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_bank';
  @override
  VerificationContext validateIntegrity(Insertable<QuestionBankData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_question_id')) {
      context.handle(
          _sourceQuestionIdMeta,
          sourceQuestionId.isAcceptableOrUnknown(
              data['source_question_id']!, _sourceQuestionIdMeta));
    }
    if (data.containsKey('knowledge_point_id')) {
      context.handle(
          _knowledgePointIdMeta,
          knowledgePointId.isAcceptableOrUnknown(
              data['knowledge_point_id']!, _knowledgePointIdMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('question_type')) {
      context.handle(
          _questionTypeMeta,
          questionType.isAcceptableOrUnknown(
              data['question_type']!, _questionTypeMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('source_label')) {
      context.handle(
          _sourceLabelMeta,
          sourceLabel.isAcceptableOrUnknown(
              data['source_label']!, _sourceLabelMeta));
    } else if (isInserting) {
      context.missing(_sourceLabelMeta);
    }
    if (data.containsKey('source_citation')) {
      context.handle(
          _sourceCitationMeta,
          sourceCitation.isAcceptableOrUnknown(
              data['source_citation']!, _sourceCitationMeta));
    }
    if (data.containsKey('used_count')) {
      context.handle(_usedCountMeta,
          usedCount.isAcceptableOrUnknown(data['used_count']!, _usedCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionBankData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionBankData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sourceQuestionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_question_id']),
      knowledgePointId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}knowledge_point_id']),
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      questionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_type'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      sourceLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_label'])!,
      sourceCitation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_citation']),
      usedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}used_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $QuestionBankTable createAlias(String alias) {
    return $QuestionBankTable(attachedDatabase, alias);
  }
}

class QuestionBankData extends DataClass
    implements Insertable<QuestionBankData> {
  /// uuid
  final String id;

  /// 来源题目（用户错题入库时关联）
  final String? sourceQuestionId;

  /// 关联知识点
  final String? knowledgePointId;

  /// 科目（Part 3.5 扩展）
  final String subject;

  /// 题型：choice / fill / solve（Part 3.5 扩展）
  final String questionType;

  /// 难度：easy / medium / hard（Part 3.5 扩展）
  final String difficulty;

  /// 题目内容 JSON：{question, options, answer, explanation}
  final String content;

  /// real_exam（用户真题）/ ai_cited（AI 真题引用）/ ai_generated（AI 拟题）
  final String kind;

  /// UI 来源标签：真题·来自你的题库 / 真题引用·2023全国甲卷 / 来源待核实 / AI 拟题
  final String sourceLabel;

  /// 出处引用原文（L2：年份+地区+考卷名；Part 3.5 扩展）
  final String? sourceCitation;

  /// 已用于练习的次数（优先未用真题）
  final int usedCount;
  final DateTime createdAt;
  const QuestionBankData(
      {required this.id,
      this.sourceQuestionId,
      this.knowledgePointId,
      required this.subject,
      required this.questionType,
      required this.difficulty,
      required this.content,
      required this.kind,
      required this.sourceLabel,
      this.sourceCitation,
      required this.usedCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sourceQuestionId != null) {
      map['source_question_id'] = Variable<String>(sourceQuestionId);
    }
    if (!nullToAbsent || knowledgePointId != null) {
      map['knowledge_point_id'] = Variable<String>(knowledgePointId);
    }
    map['subject'] = Variable<String>(subject);
    map['question_type'] = Variable<String>(questionType);
    map['difficulty'] = Variable<String>(difficulty);
    map['content'] = Variable<String>(content);
    map['kind'] = Variable<String>(kind);
    map['source_label'] = Variable<String>(sourceLabel);
    if (!nullToAbsent || sourceCitation != null) {
      map['source_citation'] = Variable<String>(sourceCitation);
    }
    map['used_count'] = Variable<int>(usedCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuestionBankCompanion toCompanion(bool nullToAbsent) {
    return QuestionBankCompanion(
      id: Value(id),
      sourceQuestionId: sourceQuestionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceQuestionId),
      knowledgePointId: knowledgePointId == null && nullToAbsent
          ? const Value.absent()
          : Value(knowledgePointId),
      subject: Value(subject),
      questionType: Value(questionType),
      difficulty: Value(difficulty),
      content: Value(content),
      kind: Value(kind),
      sourceLabel: Value(sourceLabel),
      sourceCitation: sourceCitation == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCitation),
      usedCount: Value(usedCount),
      createdAt: Value(createdAt),
    );
  }

  factory QuestionBankData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionBankData(
      id: serializer.fromJson<String>(json['id']),
      sourceQuestionId: serializer.fromJson<String?>(json['sourceQuestionId']),
      knowledgePointId: serializer.fromJson<String?>(json['knowledgePointId']),
      subject: serializer.fromJson<String>(json['subject']),
      questionType: serializer.fromJson<String>(json['questionType']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      content: serializer.fromJson<String>(json['content']),
      kind: serializer.fromJson<String>(json['kind']),
      sourceLabel: serializer.fromJson<String>(json['sourceLabel']),
      sourceCitation: serializer.fromJson<String?>(json['sourceCitation']),
      usedCount: serializer.fromJson<int>(json['usedCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceQuestionId': serializer.toJson<String?>(sourceQuestionId),
      'knowledgePointId': serializer.toJson<String?>(knowledgePointId),
      'subject': serializer.toJson<String>(subject),
      'questionType': serializer.toJson<String>(questionType),
      'difficulty': serializer.toJson<String>(difficulty),
      'content': serializer.toJson<String>(content),
      'kind': serializer.toJson<String>(kind),
      'sourceLabel': serializer.toJson<String>(sourceLabel),
      'sourceCitation': serializer.toJson<String?>(sourceCitation),
      'usedCount': serializer.toJson<int>(usedCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QuestionBankData copyWith(
          {String? id,
          Value<String?> sourceQuestionId = const Value.absent(),
          Value<String?> knowledgePointId = const Value.absent(),
          String? subject,
          String? questionType,
          String? difficulty,
          String? content,
          String? kind,
          String? sourceLabel,
          Value<String?> sourceCitation = const Value.absent(),
          int? usedCount,
          DateTime? createdAt}) =>
      QuestionBankData(
        id: id ?? this.id,
        sourceQuestionId: sourceQuestionId.present
            ? sourceQuestionId.value
            : this.sourceQuestionId,
        knowledgePointId: knowledgePointId.present
            ? knowledgePointId.value
            : this.knowledgePointId,
        subject: subject ?? this.subject,
        questionType: questionType ?? this.questionType,
        difficulty: difficulty ?? this.difficulty,
        content: content ?? this.content,
        kind: kind ?? this.kind,
        sourceLabel: sourceLabel ?? this.sourceLabel,
        sourceCitation:
            sourceCitation.present ? sourceCitation.value : this.sourceCitation,
        usedCount: usedCount ?? this.usedCount,
        createdAt: createdAt ?? this.createdAt,
      );
  QuestionBankData copyWithCompanion(QuestionBankCompanion data) {
    return QuestionBankData(
      id: data.id.present ? data.id.value : this.id,
      sourceQuestionId: data.sourceQuestionId.present
          ? data.sourceQuestionId.value
          : this.sourceQuestionId,
      knowledgePointId: data.knowledgePointId.present
          ? data.knowledgePointId.value
          : this.knowledgePointId,
      subject: data.subject.present ? data.subject.value : this.subject,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      content: data.content.present ? data.content.value : this.content,
      kind: data.kind.present ? data.kind.value : this.kind,
      sourceLabel:
          data.sourceLabel.present ? data.sourceLabel.value : this.sourceLabel,
      sourceCitation: data.sourceCitation.present
          ? data.sourceCitation.value
          : this.sourceCitation,
      usedCount: data.usedCount.present ? data.usedCount.value : this.usedCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionBankData(')
          ..write('id: $id, ')
          ..write('sourceQuestionId: $sourceQuestionId, ')
          ..write('knowledgePointId: $knowledgePointId, ')
          ..write('subject: $subject, ')
          ..write('questionType: $questionType, ')
          ..write('difficulty: $difficulty, ')
          ..write('content: $content, ')
          ..write('kind: $kind, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('sourceCitation: $sourceCitation, ')
          ..write('usedCount: $usedCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sourceQuestionId,
      knowledgePointId,
      subject,
      questionType,
      difficulty,
      content,
      kind,
      sourceLabel,
      sourceCitation,
      usedCount,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionBankData &&
          other.id == this.id &&
          other.sourceQuestionId == this.sourceQuestionId &&
          other.knowledgePointId == this.knowledgePointId &&
          other.subject == this.subject &&
          other.questionType == this.questionType &&
          other.difficulty == this.difficulty &&
          other.content == this.content &&
          other.kind == this.kind &&
          other.sourceLabel == this.sourceLabel &&
          other.sourceCitation == this.sourceCitation &&
          other.usedCount == this.usedCount &&
          other.createdAt == this.createdAt);
}

class QuestionBankCompanion extends UpdateCompanion<QuestionBankData> {
  final Value<String> id;
  final Value<String?> sourceQuestionId;
  final Value<String?> knowledgePointId;
  final Value<String> subject;
  final Value<String> questionType;
  final Value<String> difficulty;
  final Value<String> content;
  final Value<String> kind;
  final Value<String> sourceLabel;
  final Value<String?> sourceCitation;
  final Value<int> usedCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const QuestionBankCompanion({
    this.id = const Value.absent(),
    this.sourceQuestionId = const Value.absent(),
    this.knowledgePointId = const Value.absent(),
    this.subject = const Value.absent(),
    this.questionType = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.content = const Value.absent(),
    this.kind = const Value.absent(),
    this.sourceLabel = const Value.absent(),
    this.sourceCitation = const Value.absent(),
    this.usedCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionBankCompanion.insert({
    required String id,
    this.sourceQuestionId = const Value.absent(),
    this.knowledgePointId = const Value.absent(),
    this.subject = const Value.absent(),
    this.questionType = const Value.absent(),
    this.difficulty = const Value.absent(),
    required String content,
    required String kind,
    required String sourceLabel,
    this.sourceCitation = const Value.absent(),
    this.usedCount = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        content = Value(content),
        kind = Value(kind),
        sourceLabel = Value(sourceLabel),
        createdAt = Value(createdAt);
  static Insertable<QuestionBankData> custom({
    Expression<String>? id,
    Expression<String>? sourceQuestionId,
    Expression<String>? knowledgePointId,
    Expression<String>? subject,
    Expression<String>? questionType,
    Expression<String>? difficulty,
    Expression<String>? content,
    Expression<String>? kind,
    Expression<String>? sourceLabel,
    Expression<String>? sourceCitation,
    Expression<int>? usedCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceQuestionId != null) 'source_question_id': sourceQuestionId,
      if (knowledgePointId != null) 'knowledge_point_id': knowledgePointId,
      if (subject != null) 'subject': subject,
      if (questionType != null) 'question_type': questionType,
      if (difficulty != null) 'difficulty': difficulty,
      if (content != null) 'content': content,
      if (kind != null) 'kind': kind,
      if (sourceLabel != null) 'source_label': sourceLabel,
      if (sourceCitation != null) 'source_citation': sourceCitation,
      if (usedCount != null) 'used_count': usedCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionBankCompanion copyWith(
      {Value<String>? id,
      Value<String?>? sourceQuestionId,
      Value<String?>? knowledgePointId,
      Value<String>? subject,
      Value<String>? questionType,
      Value<String>? difficulty,
      Value<String>? content,
      Value<String>? kind,
      Value<String>? sourceLabel,
      Value<String?>? sourceCitation,
      Value<int>? usedCount,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return QuestionBankCompanion(
      id: id ?? this.id,
      sourceQuestionId: sourceQuestionId ?? this.sourceQuestionId,
      knowledgePointId: knowledgePointId ?? this.knowledgePointId,
      subject: subject ?? this.subject,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      content: content ?? this.content,
      kind: kind ?? this.kind,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      sourceCitation: sourceCitation ?? this.sourceCitation,
      usedCount: usedCount ?? this.usedCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceQuestionId.present) {
      map['source_question_id'] = Variable<String>(sourceQuestionId.value);
    }
    if (knowledgePointId.present) {
      map['knowledge_point_id'] = Variable<String>(knowledgePointId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (sourceLabel.present) {
      map['source_label'] = Variable<String>(sourceLabel.value);
    }
    if (sourceCitation.present) {
      map['source_citation'] = Variable<String>(sourceCitation.value);
    }
    if (usedCount.present) {
      map['used_count'] = Variable<int>(usedCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionBankCompanion(')
          ..write('id: $id, ')
          ..write('sourceQuestionId: $sourceQuestionId, ')
          ..write('knowledgePointId: $knowledgePointId, ')
          ..write('subject: $subject, ')
          ..write('questionType: $questionType, ')
          ..write('difficulty: $difficulty, ')
          ..write('content: $content, ')
          ..write('kind: $kind, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('sourceCitation: $sourceCitation, ')
          ..write('usedCount: $usedCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalysisJobsTable extends AnalysisJobs
    with TableInfo<$AnalysisJobsTable, AnalysisJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysisJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _splitResultMeta =
      const VerificationMeta('splitResult');
  @override
  late final GeneratedColumn<String> splitResult = GeneratedColumn<String>(
      'split_result', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _resultsMeta =
      const VerificationMeta('results');
  @override
  late final GeneratedColumn<String> results = GeneratedColumn<String>(
      'results', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        imagePath,
        status,
        splitResult,
        results,
        error,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analysis_jobs';
  @override
  VerificationContext validateIntegrity(Insertable<AnalysisJob> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('split_result')) {
      context.handle(
          _splitResultMeta,
          splitResult.isAcceptableOrUnknown(
              data['split_result']!, _splitResultMeta));
    }
    if (data.containsKey('results')) {
      context.handle(_resultsMeta,
          results.isAcceptableOrUnknown(data['results']!, _resultsMeta));
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalysisJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalysisJob(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      splitResult: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}split_result'])!,
      results: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}results'])!,
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AnalysisJobsTable createAlias(String alias) {
    return $AnalysisJobsTable(attachedDatabase, alias);
  }
}

class AnalysisJob extends DataClass implements Insertable<AnalysisJob> {
  /// uuid
  final String id;

  /// 题目照片本地路径
  final String imagePath;

  /// pending / splitting / analyzing / waiting_confirm / saved / abandoned / failed
  final String status;

  /// 拆题结果，JSON：[{index, text}]
  final String splitResult;

  /// 逐题解析结果，JSON：[{index, status, result?, error?}]
  final String results;

  /// 任务级错误（拆题失败等）
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AnalysisJob(
      {required this.id,
      required this.imagePath,
      required this.status,
      required this.splitResult,
      required this.results,
      this.error,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['image_path'] = Variable<String>(imagePath);
    map['status'] = Variable<String>(status);
    map['split_result'] = Variable<String>(splitResult);
    map['results'] = Variable<String>(results);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AnalysisJobsCompanion toCompanion(bool nullToAbsent) {
    return AnalysisJobsCompanion(
      id: Value(id),
      imagePath: Value(imagePath),
      status: Value(status),
      splitResult: Value(splitResult),
      results: Value(results),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AnalysisJob.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalysisJob(
      id: serializer.fromJson<String>(json['id']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      status: serializer.fromJson<String>(json['status']),
      splitResult: serializer.fromJson<String>(json['splitResult']),
      results: serializer.fromJson<String>(json['results']),
      error: serializer.fromJson<String?>(json['error']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'imagePath': serializer.toJson<String>(imagePath),
      'status': serializer.toJson<String>(status),
      'splitResult': serializer.toJson<String>(splitResult),
      'results': serializer.toJson<String>(results),
      'error': serializer.toJson<String?>(error),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AnalysisJob copyWith(
          {String? id,
          String? imagePath,
          String? status,
          String? splitResult,
          String? results,
          Value<String?> error = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AnalysisJob(
        id: id ?? this.id,
        imagePath: imagePath ?? this.imagePath,
        status: status ?? this.status,
        splitResult: splitResult ?? this.splitResult,
        results: results ?? this.results,
        error: error.present ? error.value : this.error,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AnalysisJob copyWithCompanion(AnalysisJobsCompanion data) {
    return AnalysisJob(
      id: data.id.present ? data.id.value : this.id,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      status: data.status.present ? data.status.value : this.status,
      splitResult:
          data.splitResult.present ? data.splitResult.value : this.splitResult,
      results: data.results.present ? data.results.value : this.results,
      error: data.error.present ? data.error.value : this.error,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisJob(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('status: $status, ')
          ..write('splitResult: $splitResult, ')
          ..write('results: $results, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, imagePath, status, splitResult, results, error, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalysisJob &&
          other.id == this.id &&
          other.imagePath == this.imagePath &&
          other.status == this.status &&
          other.splitResult == this.splitResult &&
          other.results == this.results &&
          other.error == this.error &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AnalysisJobsCompanion extends UpdateCompanion<AnalysisJob> {
  final Value<String> id;
  final Value<String> imagePath;
  final Value<String> status;
  final Value<String> splitResult;
  final Value<String> results;
  final Value<String?> error;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AnalysisJobsCompanion({
    this.id = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.status = const Value.absent(),
    this.splitResult = const Value.absent(),
    this.results = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysisJobsCompanion.insert({
    required String id,
    required String imagePath,
    this.status = const Value.absent(),
    this.splitResult = const Value.absent(),
    this.results = const Value.absent(),
    this.error = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        imagePath = Value(imagePath),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AnalysisJob> custom({
    Expression<String>? id,
    Expression<String>? imagePath,
    Expression<String>? status,
    Expression<String>? splitResult,
    Expression<String>? results,
    Expression<String>? error,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imagePath != null) 'image_path': imagePath,
      if (status != null) 'status': status,
      if (splitResult != null) 'split_result': splitResult,
      if (results != null) 'results': results,
      if (error != null) 'error': error,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysisJobsCompanion copyWith(
      {Value<String>? id,
      Value<String>? imagePath,
      Value<String>? status,
      Value<String>? splitResult,
      Value<String>? results,
      Value<String?>? error,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AnalysisJobsCompanion(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      splitResult: splitResult ?? this.splitResult,
      results: results ?? this.results,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (splitResult.present) {
      map['split_result'] = Variable<String>(splitResult.value);
    }
    if (results.present) {
      map['results'] = Variable<String>(results.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisJobsCompanion(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('status: $status, ')
          ..write('splitResult: $splitResult, ')
          ..write('results: $results, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KnowledgePointsTable extends KnowledgePoints
    with TableInfo<$KnowledgePointsTable, KnowledgePoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgePointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
      'version', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
      'book', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _chapterMeta =
      const VerificationMeta('chapter');
  @override
  late final GeneratedColumn<String> chapter = GeneratedColumn<String>(
      'chapter', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lessonMeta = const VerificationMeta('lesson');
  @override
  late final GeneratedColumn<String> lesson = GeneratedColumn<String>(
      'lesson', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firstSeenAtMeta =
      const VerificationMeta('firstSeenAt');
  @override
  late final GeneratedColumn<DateTime> firstSeenAt = GeneratedColumn<DateTime>(
      'first_seen_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, subject, version, book, chapter, lesson, name, firstSeenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_points';
  @override
  VerificationContext validateIntegrity(Insertable<KnowledgePoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('book')) {
      context.handle(
          _bookMeta, book.isAcceptableOrUnknown(data['book']!, _bookMeta));
    }
    if (data.containsKey('chapter')) {
      context.handle(_chapterMeta,
          chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta));
    }
    if (data.containsKey('lesson')) {
      context.handle(_lessonMeta,
          lesson.isAcceptableOrUnknown(data['lesson']!, _lessonMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
          _firstSeenAtMeta,
          firstSeenAt.isAcceptableOrUnknown(
              data['first_seen_at']!, _firstSeenAtMeta));
    } else if (isInserting) {
      context.missing(_firstSeenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {subject, name},
      ];
  @override
  KnowledgePoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgePoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version'])!,
      book: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book'])!,
      chapter: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter'])!,
      lesson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      firstSeenAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}first_seen_at'])!,
    );
  }

  @override
  $KnowledgePointsTable createAlias(String alias) {
    return $KnowledgePointsTable(attachedDatabase, alias);
  }
}

class KnowledgePoint extends DataClass implements Insertable<KnowledgePoint> {
  final String id;
  final String subject;

  /// 教材版本，如 人教版（可推断必须可改）
  final String version;

  /// 册别，如 八年级上册
  final String book;

  /// 章
  final String chapter;

  /// 节
  final String lesson;

  /// 知识点名称（最末级）
  final String name;
  final DateTime firstSeenAt;
  const KnowledgePoint(
      {required this.id,
      required this.subject,
      required this.version,
      required this.book,
      required this.chapter,
      required this.lesson,
      required this.name,
      required this.firstSeenAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject'] = Variable<String>(subject);
    map['version'] = Variable<String>(version);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<String>(chapter);
    map['lesson'] = Variable<String>(lesson);
    map['name'] = Variable<String>(name);
    map['first_seen_at'] = Variable<DateTime>(firstSeenAt);
    return map;
  }

  KnowledgePointsCompanion toCompanion(bool nullToAbsent) {
    return KnowledgePointsCompanion(
      id: Value(id),
      subject: Value(subject),
      version: Value(version),
      book: Value(book),
      chapter: Value(chapter),
      lesson: Value(lesson),
      name: Value(name),
      firstSeenAt: Value(firstSeenAt),
    );
  }

  factory KnowledgePoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgePoint(
      id: serializer.fromJson<String>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      version: serializer.fromJson<String>(json['version']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<String>(json['chapter']),
      lesson: serializer.fromJson<String>(json['lesson']),
      name: serializer.fromJson<String>(json['name']),
      firstSeenAt: serializer.fromJson<DateTime>(json['firstSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subject': serializer.toJson<String>(subject),
      'version': serializer.toJson<String>(version),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<String>(chapter),
      'lesson': serializer.toJson<String>(lesson),
      'name': serializer.toJson<String>(name),
      'firstSeenAt': serializer.toJson<DateTime>(firstSeenAt),
    };
  }

  KnowledgePoint copyWith(
          {String? id,
          String? subject,
          String? version,
          String? book,
          String? chapter,
          String? lesson,
          String? name,
          DateTime? firstSeenAt}) =>
      KnowledgePoint(
        id: id ?? this.id,
        subject: subject ?? this.subject,
        version: version ?? this.version,
        book: book ?? this.book,
        chapter: chapter ?? this.chapter,
        lesson: lesson ?? this.lesson,
        name: name ?? this.name,
        firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      );
  KnowledgePoint copyWithCompanion(KnowledgePointsCompanion data) {
    return KnowledgePoint(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      version: data.version.present ? data.version.value : this.version,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      lesson: data.lesson.present ? data.lesson.value : this.lesson,
      name: data.name.present ? data.name.value : this.name,
      firstSeenAt:
          data.firstSeenAt.present ? data.firstSeenAt.value : this.firstSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgePoint(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('version: $version, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('lesson: $lesson, ')
          ..write('name: $name, ')
          ..write('firstSeenAt: $firstSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, subject, version, book, chapter, lesson, name, firstSeenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgePoint &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.version == this.version &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.lesson == this.lesson &&
          other.name == this.name &&
          other.firstSeenAt == this.firstSeenAt);
}

class KnowledgePointsCompanion extends UpdateCompanion<KnowledgePoint> {
  final Value<String> id;
  final Value<String> subject;
  final Value<String> version;
  final Value<String> book;
  final Value<String> chapter;
  final Value<String> lesson;
  final Value<String> name;
  final Value<DateTime> firstSeenAt;
  final Value<int> rowid;
  const KnowledgePointsCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.version = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.lesson = const Value.absent(),
    this.name = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnowledgePointsCompanion.insert({
    required String id,
    this.subject = const Value.absent(),
    this.version = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.lesson = const Value.absent(),
    required String name,
    required DateTime firstSeenAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        firstSeenAt = Value(firstSeenAt);
  static Insertable<KnowledgePoint> custom({
    Expression<String>? id,
    Expression<String>? subject,
    Expression<String>? version,
    Expression<String>? book,
    Expression<String>? chapter,
    Expression<String>? lesson,
    Expression<String>? name,
    Expression<DateTime>? firstSeenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (version != null) 'version': version,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (lesson != null) 'lesson': lesson,
      if (name != null) 'name': name,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnowledgePointsCompanion copyWith(
      {Value<String>? id,
      Value<String>? subject,
      Value<String>? version,
      Value<String>? book,
      Value<String>? chapter,
      Value<String>? lesson,
      Value<String>? name,
      Value<DateTime>? firstSeenAt,
      Value<int>? rowid}) {
    return KnowledgePointsCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      version: version ?? this.version,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      lesson: lesson ?? this.lesson,
      name: name ?? this.name,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<String>(chapter.value);
    }
    if (lesson.present) {
      map['lesson'] = Variable<String>(lesson.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<DateTime>(firstSeenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgePointsCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('version: $version, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('lesson: $lesson, ')
          ..write('name: $name, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionKnowledgeLinksTable extends QuestionKnowledgeLinks
    with TableInfo<$QuestionKnowledgeLinksTable, QuestionKnowledgeLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionKnowledgeLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _knowledgePointIdMeta =
      const VerificationMeta('knowledgePointId');
  @override
  late final GeneratedColumn<String> knowledgePointId = GeneratedColumn<String>(
      'knowledge_point_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, questionId, knowledgePointId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_knowledge_links';
  @override
  VerificationContext validateIntegrity(
      Insertable<QuestionKnowledgeLink> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('knowledge_point_id')) {
      context.handle(
          _knowledgePointIdMeta,
          knowledgePointId.isAcceptableOrUnknown(
              data['knowledge_point_id']!, _knowledgePointIdMeta));
    } else if (isInserting) {
      context.missing(_knowledgePointIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionKnowledgeLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionKnowledgeLink(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      knowledgePointId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}knowledge_point_id'])!,
    );
  }

  @override
  $QuestionKnowledgeLinksTable createAlias(String alias) {
    return $QuestionKnowledgeLinksTable(attachedDatabase, alias);
  }
}

class QuestionKnowledgeLink extends DataClass
    implements Insertable<QuestionKnowledgeLink> {
  final int id;
  final String questionId;
  final String knowledgePointId;
  const QuestionKnowledgeLink(
      {required this.id,
      required this.questionId,
      required this.knowledgePointId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['knowledge_point_id'] = Variable<String>(knowledgePointId);
    return map;
  }

  QuestionKnowledgeLinksCompanion toCompanion(bool nullToAbsent) {
    return QuestionKnowledgeLinksCompanion(
      id: Value(id),
      questionId: Value(questionId),
      knowledgePointId: Value(knowledgePointId),
    );
  }

  factory QuestionKnowledgeLink.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionKnowledgeLink(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      knowledgePointId: serializer.fromJson<String>(json['knowledgePointId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'knowledgePointId': serializer.toJson<String>(knowledgePointId),
    };
  }

  QuestionKnowledgeLink copyWith(
          {int? id, String? questionId, String? knowledgePointId}) =>
      QuestionKnowledgeLink(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        knowledgePointId: knowledgePointId ?? this.knowledgePointId,
      );
  QuestionKnowledgeLink copyWithCompanion(
      QuestionKnowledgeLinksCompanion data) {
    return QuestionKnowledgeLink(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      knowledgePointId: data.knowledgePointId.present
          ? data.knowledgePointId.value
          : this.knowledgePointId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionKnowledgeLink(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('knowledgePointId: $knowledgePointId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionId, knowledgePointId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionKnowledgeLink &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.knowledgePointId == this.knowledgePointId);
}

class QuestionKnowledgeLinksCompanion
    extends UpdateCompanion<QuestionKnowledgeLink> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<String> knowledgePointId;
  const QuestionKnowledgeLinksCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.knowledgePointId = const Value.absent(),
  });
  QuestionKnowledgeLinksCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required String knowledgePointId,
  })  : questionId = Value(questionId),
        knowledgePointId = Value(knowledgePointId);
  static Insertable<QuestionKnowledgeLink> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<String>? knowledgePointId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (knowledgePointId != null) 'knowledge_point_id': knowledgePointId,
    });
  }

  QuestionKnowledgeLinksCompanion copyWith(
      {Value<int>? id,
      Value<String>? questionId,
      Value<String>? knowledgePointId}) {
    return QuestionKnowledgeLinksCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      knowledgePointId: knowledgePointId ?? this.knowledgePointId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (knowledgePointId.present) {
      map['knowledge_point_id'] = Variable<String>(knowledgePointId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionKnowledgeLinksCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('knowledgePointId: $knowledgePointId')
          ..write(')'))
        .toString();
  }
}

class $ReviewCardsTable extends ReviewCards
    with TableInfo<$ReviewCardsTable, ReviewCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
      'due', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
      'state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
      'step', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _stabilityMeta =
      const VerificationMeta('stability');
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
      'stability', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _easinessFactorMeta =
      const VerificationMeta('easinessFactor');
  @override
  late final GeneratedColumn<double> easinessFactor = GeneratedColumn<double>(
      'easiness_factor', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(2.5));
  static const VerificationMeta _intervalDaysMeta =
      const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
      'interval_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
      'lapses', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReviewAtMeta =
      const VerificationMeta('lastReviewAt');
  @override
  late final GeneratedColumn<DateTime> lastReviewAt = GeneratedColumn<DateTime>(
      'last_review_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        questionId,
        due,
        state,
        step,
        stability,
        difficulty,
        easinessFactor,
        intervalDays,
        reps,
        lapses,
        lastReviewAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_cards';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewCard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('due')) {
      context.handle(
          _dueMeta, due.isAcceptableOrUnknown(data['due']!, _dueMeta));
    } else if (isInserting) {
      context.missing(_dueMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('step')) {
      context.handle(
          _stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    }
    if (data.containsKey('stability')) {
      context.handle(_stabilityMeta,
          stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('easiness_factor')) {
      context.handle(
          _easinessFactorMeta,
          easinessFactor.isAcceptableOrUnknown(
              data['easiness_factor']!, _easinessFactorMeta));
    }
    if (data.containsKey('interval_days')) {
      context.handle(
          _intervalDaysMeta,
          intervalDays.isAcceptableOrUnknown(
              data['interval_days']!, _intervalDaysMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('lapses')) {
      context.handle(_lapsesMeta,
          lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta));
    }
    if (data.containsKey('last_review_at')) {
      context.handle(
          _lastReviewAtMeta,
          lastReviewAt.isAcceptableOrUnknown(
              data['last_review_at']!, _lastReviewAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewCard(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      due: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state'])!,
      step: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step']),
      stability: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stability'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}difficulty'])!,
      easinessFactor: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}easiness_factor'])!,
      intervalDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval_days'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      lapses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lapses'])!,
      lastReviewAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_review_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ReviewCardsTable createAlias(String alias) {
    return $ReviewCardsTable(attachedDatabase, alias);
  }
}

class ReviewCard extends DataClass implements Insertable<ReviewCard> {
  final String id;

  /// 关联题目
  final String questionId;

  /// 到期时间
  final DateTime due;

  /// SM-2 评分档：0 new / 1 learning / 2 review / 3 relearning（兼容旧数据）
  final int state;

  /// 旧 FSRS 字段（保留兼容旧数据，不再使用）
  final int? step;
  final double stability;
  final double difficulty;

  /// SM-2 算法字段
  final double easinessFactor;
  final int intervalDays;
  final int reps;
  final int lapses;
  final DateTime? lastReviewAt;
  final DateTime createdAt;
  const ReviewCard(
      {required this.id,
      required this.questionId,
      required this.due,
      required this.state,
      this.step,
      required this.stability,
      required this.difficulty,
      required this.easinessFactor,
      required this.intervalDays,
      required this.reps,
      required this.lapses,
      this.lastReviewAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_id'] = Variable<String>(questionId);
    map['due'] = Variable<DateTime>(due);
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['easiness_factor'] = Variable<double>(easinessFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || lastReviewAt != null) {
      map['last_review_at'] = Variable<DateTime>(lastReviewAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReviewCardsCompanion toCompanion(bool nullToAbsent) {
    return ReviewCardsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      due: Value(due),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      stability: Value(stability),
      difficulty: Value(difficulty),
      easinessFactor: Value(easinessFactor),
      intervalDays: Value(intervalDays),
      reps: Value(reps),
      lapses: Value(lapses),
      lastReviewAt: lastReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewAt),
      createdAt: Value(createdAt),
    );
  }

  factory ReviewCard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewCard(
      id: serializer.fromJson<String>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      due: serializer.fromJson<DateTime>(json['due']),
      state: serializer.fromJson<int>(json['state']),
      step: serializer.fromJson<int?>(json['step']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      easinessFactor: serializer.fromJson<double>(json['easinessFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      lastReviewAt: serializer.fromJson<DateTime?>(json['lastReviewAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionId': serializer.toJson<String>(questionId),
      'due': serializer.toJson<DateTime>(due),
      'state': serializer.toJson<int>(state),
      'step': serializer.toJson<int?>(step),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'easinessFactor': serializer.toJson<double>(easinessFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'lastReviewAt': serializer.toJson<DateTime?>(lastReviewAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReviewCard copyWith(
          {String? id,
          String? questionId,
          DateTime? due,
          int? state,
          Value<int?> step = const Value.absent(),
          double? stability,
          double? difficulty,
          double? easinessFactor,
          int? intervalDays,
          int? reps,
          int? lapses,
          Value<DateTime?> lastReviewAt = const Value.absent(),
          DateTime? createdAt}) =>
      ReviewCard(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        due: due ?? this.due,
        state: state ?? this.state,
        step: step.present ? step.value : this.step,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        easinessFactor: easinessFactor ?? this.easinessFactor,
        intervalDays: intervalDays ?? this.intervalDays,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        lastReviewAt:
            lastReviewAt.present ? lastReviewAt.value : this.lastReviewAt,
        createdAt: createdAt ?? this.createdAt,
      );
  ReviewCard copyWithCompanion(ReviewCardsCompanion data) {
    return ReviewCard(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      due: data.due.present ? data.due.value : this.due,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      easinessFactor: data.easinessFactor.present
          ? data.easinessFactor.value
          : this.easinessFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      lastReviewAt: data.lastReviewAt.present
          ? data.lastReviewAt.value
          : this.lastReviewAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCard(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('due: $due, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('easinessFactor: $easinessFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewAt: $lastReviewAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      questionId,
      due,
      state,
      step,
      stability,
      difficulty,
      easinessFactor,
      intervalDays,
      reps,
      lapses,
      lastReviewAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewCard &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.due == this.due &&
          other.state == this.state &&
          other.step == this.step &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.easinessFactor == this.easinessFactor &&
          other.intervalDays == this.intervalDays &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.lastReviewAt == this.lastReviewAt &&
          other.createdAt == this.createdAt);
}

class ReviewCardsCompanion extends UpdateCompanion<ReviewCard> {
  final Value<String> id;
  final Value<String> questionId;
  final Value<DateTime> due;
  final Value<int> state;
  final Value<int?> step;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<double> easinessFactor;
  final Value<int> intervalDays;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<DateTime?> lastReviewAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReviewCardsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.due = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.easinessFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewCardsCompanion.insert({
    required String id,
    required String questionId,
    required DateTime due,
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.easinessFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        questionId = Value(questionId),
        due = Value(due),
        createdAt = Value(createdAt);
  static Insertable<ReviewCard> custom({
    Expression<String>? id,
    Expression<String>? questionId,
    Expression<DateTime>? due,
    Expression<int>? state,
    Expression<int>? step,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<double>? easinessFactor,
    Expression<int>? intervalDays,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<DateTime>? lastReviewAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (due != null) 'due': due,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (easinessFactor != null) 'easiness_factor': easinessFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (lastReviewAt != null) 'last_review_at': lastReviewAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewCardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? questionId,
      Value<DateTime>? due,
      Value<int>? state,
      Value<int?>? step,
      Value<double>? stability,
      Value<double>? difficulty,
      Value<double>? easinessFactor,
      Value<int>? intervalDays,
      Value<int>? reps,
      Value<int>? lapses,
      Value<DateTime?>? lastReviewAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ReviewCardsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      due: due ?? this.due,
      state: state ?? this.state,
      step: step ?? this.step,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (easinessFactor.present) {
      map['easiness_factor'] = Variable<double>(easinessFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (lastReviewAt.present) {
      map['last_review_at'] = Variable<DateTime>(lastReviewAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCardsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('due: $due, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('easinessFactor: $easinessFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewAt: $lastReviewAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reviewedAtMeta =
      const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
      'reviewed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, questionId, rating, reviewedAt, durationMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
          _reviewedAtMeta,
          reviewedAt.isAcceptableOrUnknown(
              data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating'])!,
      reviewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reviewed_at'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final int id;
  final String questionId;

  /// SM-2 评分：1=仍错, 3=模糊, 5=已会
  final int rating;
  final DateTime reviewedAt;
  final int? durationMs;
  const ReviewLog(
      {required this.id,
      required this.questionId,
      required this.rating,
      required this.reviewedAt,
      this.durationMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['rating'] = Variable<int>(rating);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      rating: Value(rating),
      reviewedAt: Value(reviewedAt),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
    );
  }

  factory ReviewLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'rating': serializer.toJson<int>(rating),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'durationMs': serializer.toJson<int?>(durationMs),
    };
  }

  ReviewLog copyWith(
          {int? id,
          String? questionId,
          int? rating,
          DateTime? reviewedAt,
          Value<int?> durationMs = const Value.absent()}) =>
      ReviewLog(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        rating: rating ?? this.rating,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
      );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewedAt:
          data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, questionId, rating, reviewedAt, durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.rating == this.rating &&
          other.reviewedAt == this.reviewedAt &&
          other.durationMs == this.durationMs);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<int> rating;
  final Value<DateTime> reviewedAt;
  final Value<int?> durationMs;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required int rating,
    required DateTime reviewedAt,
    this.durationMs = const Value.absent(),
  })  : questionId = Value(questionId),
        rating = Value(rating),
        reviewedAt = Value(reviewedAt);
  static Insertable<ReviewLog> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<int>? rating,
    Expression<DateTime>? reviewedAt,
    Expression<int>? durationMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (rating != null) 'rating': rating,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (durationMs != null) 'duration_ms': durationMs,
    });
  }

  ReviewLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? questionId,
      Value<int>? rating,
      Value<DateTime>? reviewedAt,
      Value<int?>? durationMs}) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      rating: rating ?? this.rating,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }
}

class $GeneratedExercisesTable extends GeneratedExercises
    with TableInfo<$GeneratedExercisesTable, GeneratedExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneratedExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, questionId, content, status, createdAt, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generated_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<GeneratedExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeneratedExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneratedExercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $GeneratedExercisesTable createAlias(String alias) {
    return $GeneratedExercisesTable(attachedDatabase, alias);
  }
}

class GeneratedExercise extends DataClass
    implements Insertable<GeneratedExercise> {
  final String id;

  /// 来源错题
  final String questionId;

  /// 练习题内容，JSON（题目列表 + 参考答案）
  final String content;

  /// pending / in_progress / completed / abandoned
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  const GeneratedExercise(
      {required this.id,
      required this.questionId,
      required this.content,
      required this.status,
      required this.createdAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_id'] = Variable<String>(questionId);
    map['content'] = Variable<String>(content);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  GeneratedExercisesCompanion toCompanion(bool nullToAbsent) {
    return GeneratedExercisesCompanion(
      id: Value(id),
      questionId: Value(questionId),
      content: Value(content),
      status: Value(status),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory GeneratedExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneratedExercise(
      id: serializer.fromJson<String>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      content: serializer.fromJson<String>(json['content']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionId': serializer.toJson<String>(questionId),
      'content': serializer.toJson<String>(content),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  GeneratedExercise copyWith(
          {String? id,
          String? questionId,
          String? content,
          String? status,
          DateTime? createdAt,
          Value<DateTime?> completedAt = const Value.absent()}) =>
      GeneratedExercise(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        content: content ?? this.content,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  GeneratedExercise copyWithCompanion(GeneratedExercisesCompanion data) {
    return GeneratedExercise(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      content: data.content.present ? data.content.value : this.content,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedExercise(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, questionId, content, status, createdAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneratedExercise &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.content == this.content &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class GeneratedExercisesCompanion extends UpdateCompanion<GeneratedExercise> {
  final Value<String> id;
  final Value<String> questionId;
  final Value<String> content;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const GeneratedExercisesCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.content = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneratedExercisesCompanion.insert({
    required String id,
    required String questionId,
    required String content,
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        questionId = Value(questionId),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<GeneratedExercise> custom({
    Expression<String>? id,
    Expression<String>? questionId,
    Expression<String>? content,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (content != null) 'content': content,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneratedExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? questionId,
      Value<String>? content,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime?>? completedAt,
      Value<int>? rowid}) {
    return GeneratedExercisesCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiMessagesTable extends AiMessages
    with TableInfo<$AiMessagesTable, AiMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, questionId, role, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_messages';
  @override
  VerificationContext validateIntegrity(Insertable<AiMessageRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiMessageRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id']),
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AiMessagesTable createAlias(String alias) {
    return $AiMessagesTable(attachedDatabase, alias);
  }
}

class AiMessageRow extends DataClass implements Insertable<AiMessageRow> {
  final int id;
  final String? questionId;

  /// user / assistant / system
  final String role;
  final String content;
  final DateTime createdAt;
  const AiMessageRow(
      {required this.id,
      this.questionId,
      required this.role,
      required this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || questionId != null) {
      map['question_id'] = Variable<String>(questionId);
    }
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiMessagesCompanion toCompanion(bool nullToAbsent) {
    return AiMessagesCompanion(
      id: Value(id),
      questionId: questionId == null && nullToAbsent
          ? const Value.absent()
          : Value(questionId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory AiMessageRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiMessageRow(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String?>(json['questionId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String?>(questionId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiMessageRow copyWith(
          {int? id,
          Value<String?> questionId = const Value.absent(),
          String? role,
          String? content,
          DateTime? createdAt}) =>
      AiMessageRow(
        id: id ?? this.id,
        questionId: questionId.present ? questionId.value : this.questionId,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  AiMessageRow copyWithCompanion(AiMessagesCompanion data) {
    return AiMessageRow(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiMessageRow(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiMessageRow &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class AiMessagesCompanion extends UpdateCompanion<AiMessageRow> {
  final Value<int> id;
  final Value<String?> questionId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const AiMessagesCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AiMessagesCompanion.insert({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    required String role,
    required String content,
    required DateTime createdAt,
  })  : role = Value(role),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<AiMessageRow> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AiMessagesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? questionId,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? createdAt}) {
    return AiMessagesCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiMessagesCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LearningEventsTable extends LearningEvents
    with TableInfo<$LearningEventsTable, LearningEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
      'at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, eventType, questionId, at, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_events';
  @override
  VerificationContext validateIntegrity(Insertable<LearningEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id']),
      at: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
    );
  }

  @override
  $LearningEventsTable createAlias(String alias) {
    return $LearningEventsTable(attachedDatabase, alias);
  }
}

class LearningEvent extends DataClass implements Insertable<LearningEvent> {
  final int id;
  final String eventType;
  final String? questionId;
  final DateTime at;
  final String payload;
  const LearningEvent(
      {required this.id,
      required this.eventType,
      this.questionId,
      required this.at,
      required this.payload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || questionId != null) {
      map['question_id'] = Variable<String>(questionId);
    }
    map['at'] = Variable<DateTime>(at);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  LearningEventsCompanion toCompanion(bool nullToAbsent) {
    return LearningEventsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      questionId: questionId == null && nullToAbsent
          ? const Value.absent()
          : Value(questionId),
      at: Value(at),
      payload: Value(payload),
    );
  }

  factory LearningEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningEvent(
      id: serializer.fromJson<int>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      questionId: serializer.fromJson<String?>(json['questionId']),
      at: serializer.fromJson<DateTime>(json['at']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventType': serializer.toJson<String>(eventType),
      'questionId': serializer.toJson<String?>(questionId),
      'at': serializer.toJson<DateTime>(at),
      'payload': serializer.toJson<String>(payload),
    };
  }

  LearningEvent copyWith(
          {int? id,
          String? eventType,
          Value<String?> questionId = const Value.absent(),
          DateTime? at,
          String? payload}) =>
      LearningEvent(
        id: id ?? this.id,
        eventType: eventType ?? this.eventType,
        questionId: questionId.present ? questionId.value : this.questionId,
        at: at ?? this.at,
        payload: payload ?? this.payload,
      );
  LearningEvent copyWithCompanion(LearningEventsCompanion data) {
    return LearningEvent(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      at: data.at.present ? data.at.value : this.at,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningEvent(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('questionId: $questionId, ')
          ..write('at: $at, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventType, questionId, at, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningEvent &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.questionId == this.questionId &&
          other.at == this.at &&
          other.payload == this.payload);
}

class LearningEventsCompanion extends UpdateCompanion<LearningEvent> {
  final Value<int> id;
  final Value<String> eventType;
  final Value<String?> questionId;
  final Value<DateTime> at;
  final Value<String> payload;
  const LearningEventsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.questionId = const Value.absent(),
    this.at = const Value.absent(),
    this.payload = const Value.absent(),
  });
  LearningEventsCompanion.insert({
    this.id = const Value.absent(),
    required String eventType,
    this.questionId = const Value.absent(),
    required DateTime at,
    this.payload = const Value.absent(),
  })  : eventType = Value(eventType),
        at = Value(at);
  static Insertable<LearningEvent> custom({
    Expression<int>? id,
    Expression<String>? eventType,
    Expression<String>? questionId,
    Expression<DateTime>? at,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (questionId != null) 'question_id': questionId,
      if (at != null) 'at': at,
      if (payload != null) 'payload': payload,
    });
  }

  LearningEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? eventType,
      Value<String?>? questionId,
      Value<DateTime>? at,
      Value<String>? payload}) {
    return LearningEventsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      questionId: questionId ?? this.questionId,
      at: at ?? this.at,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('questionId: $questionId, ')
          ..write('at: $at, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $GrowthMetricsTable extends GrowthMetrics
    with TableInfo<$GrowthMetricsTable, GrowthMetric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrowthMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _learningScoreMeta =
      const VerificationMeta('learningScore');
  @override
  late final GeneratedColumn<double> learningScore = GeneratedColumn<double>(
      'learning_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _persistenceScoreMeta =
      const VerificationMeta('persistenceScore');
  @override
  late final GeneratedColumn<double> persistenceScore = GeneratedColumn<double>(
      'persistence_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _recoveryScoreMeta =
      const VerificationMeta('recoveryScore');
  @override
  late final GeneratedColumn<double> recoveryScore = GeneratedColumn<double>(
      'recovery_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reviewDoneMeta =
      const VerificationMeta('reviewDone');
  @override
  late final GeneratedColumn<int> reviewDone = GeneratedColumn<int>(
      'review_done', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reviewDueMeta =
      const VerificationMeta('reviewDue');
  @override
  late final GeneratedColumn<int> reviewDue = GeneratedColumn<int>(
      'review_due', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _streakMeta = const VerificationMeta('streak');
  @override
  late final GeneratedColumn<int> streak = GeneratedColumn<int>(
      'streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _snapshotJsonMeta =
      const VerificationMeta('snapshotJson');
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
      'snapshot_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns => [
        date,
        learningScore,
        persistenceScore,
        recoveryScore,
        reviewDone,
        reviewDue,
        streak,
        snapshotJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'growth_metrics';
  @override
  VerificationContext validateIntegrity(Insertable<GrowthMetric> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('learning_score')) {
      context.handle(
          _learningScoreMeta,
          learningScore.isAcceptableOrUnknown(
              data['learning_score']!, _learningScoreMeta));
    }
    if (data.containsKey('persistence_score')) {
      context.handle(
          _persistenceScoreMeta,
          persistenceScore.isAcceptableOrUnknown(
              data['persistence_score']!, _persistenceScoreMeta));
    }
    if (data.containsKey('recovery_score')) {
      context.handle(
          _recoveryScoreMeta,
          recoveryScore.isAcceptableOrUnknown(
              data['recovery_score']!, _recoveryScoreMeta));
    }
    if (data.containsKey('review_done')) {
      context.handle(
          _reviewDoneMeta,
          reviewDone.isAcceptableOrUnknown(
              data['review_done']!, _reviewDoneMeta));
    }
    if (data.containsKey('review_due')) {
      context.handle(_reviewDueMeta,
          reviewDue.isAcceptableOrUnknown(data['review_due']!, _reviewDueMeta));
    }
    if (data.containsKey('streak')) {
      context.handle(_streakMeta,
          streak.isAcceptableOrUnknown(data['streak']!, _streakMeta));
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
          _snapshotJsonMeta,
          snapshotJson.isAcceptableOrUnknown(
              data['snapshot_json']!, _snapshotJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  GrowthMetric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrowthMetric(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      learningScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}learning_score'])!,
      persistenceScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}persistence_score'])!,
      recoveryScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}recovery_score'])!,
      reviewDone: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_done'])!,
      reviewDue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_due'])!,
      streak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}streak'])!,
      snapshotJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_json'])!,
    );
  }

  @override
  $GrowthMetricsTable createAlias(String alias) {
    return $GrowthMetricsTable(attachedDatabase, alias);
  }
}

class GrowthMetric extends DataClass implements Insertable<GrowthMetric> {
  /// yyyy-MM-dd，一天一行
  final String date;

  /// 学习 / 坚持 / 恢复，0-100（三能力模型）
  final double learningScore;
  final double persistenceScore;
  final double recoveryScore;
  final int reviewDone;
  final int reviewDue;
  final int streak;
  final String snapshotJson;
  const GrowthMetric(
      {required this.date,
      required this.learningScore,
      required this.persistenceScore,
      required this.recoveryScore,
      required this.reviewDone,
      required this.reviewDue,
      required this.streak,
      required this.snapshotJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['learning_score'] = Variable<double>(learningScore);
    map['persistence_score'] = Variable<double>(persistenceScore);
    map['recovery_score'] = Variable<double>(recoveryScore);
    map['review_done'] = Variable<int>(reviewDone);
    map['review_due'] = Variable<int>(reviewDue);
    map['streak'] = Variable<int>(streak);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    return map;
  }

  GrowthMetricsCompanion toCompanion(bool nullToAbsent) {
    return GrowthMetricsCompanion(
      date: Value(date),
      learningScore: Value(learningScore),
      persistenceScore: Value(persistenceScore),
      recoveryScore: Value(recoveryScore),
      reviewDone: Value(reviewDone),
      reviewDue: Value(reviewDue),
      streak: Value(streak),
      snapshotJson: Value(snapshotJson),
    );
  }

  factory GrowthMetric.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrowthMetric(
      date: serializer.fromJson<String>(json['date']),
      learningScore: serializer.fromJson<double>(json['learningScore']),
      persistenceScore: serializer.fromJson<double>(json['persistenceScore']),
      recoveryScore: serializer.fromJson<double>(json['recoveryScore']),
      reviewDone: serializer.fromJson<int>(json['reviewDone']),
      reviewDue: serializer.fromJson<int>(json['reviewDue']),
      streak: serializer.fromJson<int>(json['streak']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'learningScore': serializer.toJson<double>(learningScore),
      'persistenceScore': serializer.toJson<double>(persistenceScore),
      'recoveryScore': serializer.toJson<double>(recoveryScore),
      'reviewDone': serializer.toJson<int>(reviewDone),
      'reviewDue': serializer.toJson<int>(reviewDue),
      'streak': serializer.toJson<int>(streak),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
    };
  }

  GrowthMetric copyWith(
          {String? date,
          double? learningScore,
          double? persistenceScore,
          double? recoveryScore,
          int? reviewDone,
          int? reviewDue,
          int? streak,
          String? snapshotJson}) =>
      GrowthMetric(
        date: date ?? this.date,
        learningScore: learningScore ?? this.learningScore,
        persistenceScore: persistenceScore ?? this.persistenceScore,
        recoveryScore: recoveryScore ?? this.recoveryScore,
        reviewDone: reviewDone ?? this.reviewDone,
        reviewDue: reviewDue ?? this.reviewDue,
        streak: streak ?? this.streak,
        snapshotJson: snapshotJson ?? this.snapshotJson,
      );
  GrowthMetric copyWithCompanion(GrowthMetricsCompanion data) {
    return GrowthMetric(
      date: data.date.present ? data.date.value : this.date,
      learningScore: data.learningScore.present
          ? data.learningScore.value
          : this.learningScore,
      persistenceScore: data.persistenceScore.present
          ? data.persistenceScore.value
          : this.persistenceScore,
      recoveryScore: data.recoveryScore.present
          ? data.recoveryScore.value
          : this.recoveryScore,
      reviewDone:
          data.reviewDone.present ? data.reviewDone.value : this.reviewDone,
      reviewDue: data.reviewDue.present ? data.reviewDue.value : this.reviewDue,
      streak: data.streak.present ? data.streak.value : this.streak,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrowthMetric(')
          ..write('date: $date, ')
          ..write('learningScore: $learningScore, ')
          ..write('persistenceScore: $persistenceScore, ')
          ..write('recoveryScore: $recoveryScore, ')
          ..write('reviewDone: $reviewDone, ')
          ..write('reviewDue: $reviewDue, ')
          ..write('streak: $streak, ')
          ..write('snapshotJson: $snapshotJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, learningScore, persistenceScore,
      recoveryScore, reviewDone, reviewDue, streak, snapshotJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrowthMetric &&
          other.date == this.date &&
          other.learningScore == this.learningScore &&
          other.persistenceScore == this.persistenceScore &&
          other.recoveryScore == this.recoveryScore &&
          other.reviewDone == this.reviewDone &&
          other.reviewDue == this.reviewDue &&
          other.streak == this.streak &&
          other.snapshotJson == this.snapshotJson);
}

class GrowthMetricsCompanion extends UpdateCompanion<GrowthMetric> {
  final Value<String> date;
  final Value<double> learningScore;
  final Value<double> persistenceScore;
  final Value<double> recoveryScore;
  final Value<int> reviewDone;
  final Value<int> reviewDue;
  final Value<int> streak;
  final Value<String> snapshotJson;
  final Value<int> rowid;
  const GrowthMetricsCompanion({
    this.date = const Value.absent(),
    this.learningScore = const Value.absent(),
    this.persistenceScore = const Value.absent(),
    this.recoveryScore = const Value.absent(),
    this.reviewDone = const Value.absent(),
    this.reviewDue = const Value.absent(),
    this.streak = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrowthMetricsCompanion.insert({
    required String date,
    this.learningScore = const Value.absent(),
    this.persistenceScore = const Value.absent(),
    this.recoveryScore = const Value.absent(),
    this.reviewDone = const Value.absent(),
    this.reviewDue = const Value.absent(),
    this.streak = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<GrowthMetric> custom({
    Expression<String>? date,
    Expression<double>? learningScore,
    Expression<double>? persistenceScore,
    Expression<double>? recoveryScore,
    Expression<int>? reviewDone,
    Expression<int>? reviewDue,
    Expression<int>? streak,
    Expression<String>? snapshotJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (learningScore != null) 'learning_score': learningScore,
      if (persistenceScore != null) 'persistence_score': persistenceScore,
      if (recoveryScore != null) 'recovery_score': recoveryScore,
      if (reviewDone != null) 'review_done': reviewDone,
      if (reviewDue != null) 'review_due': reviewDue,
      if (streak != null) 'streak': streak,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrowthMetricsCompanion copyWith(
      {Value<String>? date,
      Value<double>? learningScore,
      Value<double>? persistenceScore,
      Value<double>? recoveryScore,
      Value<int>? reviewDone,
      Value<int>? reviewDue,
      Value<int>? streak,
      Value<String>? snapshotJson,
      Value<int>? rowid}) {
    return GrowthMetricsCompanion(
      date: date ?? this.date,
      learningScore: learningScore ?? this.learningScore,
      persistenceScore: persistenceScore ?? this.persistenceScore,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      reviewDone: reviewDone ?? this.reviewDone,
      reviewDue: reviewDue ?? this.reviewDue,
      streak: streak ?? this.streak,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (learningScore.present) {
      map['learning_score'] = Variable<double>(learningScore.value);
    }
    if (persistenceScore.present) {
      map['persistence_score'] = Variable<double>(persistenceScore.value);
    }
    if (recoveryScore.present) {
      map['recovery_score'] = Variable<double>(recoveryScore.value);
    }
    if (reviewDone.present) {
      map['review_done'] = Variable<int>(reviewDone.value);
    }
    if (reviewDue.present) {
      map['review_due'] = Variable<int>(reviewDue.value);
    }
    if (streak.present) {
      map['streak'] = Variable<int>(streak.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrowthMetricsCompanion(')
          ..write('date: $date, ')
          ..write('learningScore: $learningScore, ')
          ..write('persistenceScore: $persistenceScore, ')
          ..write('recoveryScore: $recoveryScore, ')
          ..write('reviewDone: $reviewDone, ')
          ..write('reviewDue: $reviewDue, ')
          ..write('streak: $streak, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiProvidersTable extends AiProviders
    with TableInfo<$AiProvidersTable, AiProvider> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiProvidersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseUrlMeta =
      const VerificationMeta('baseUrl');
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
      'base_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyRefMeta = const VerificationMeta('keyRef');
  @override
  late final GeneratedColumn<String> keyRef = GeneratedColumn<String>(
      'key_ref', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, baseUrl, model, keyRef, isDefault, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_providers';
  @override
  VerificationContext validateIntegrity(Insertable<AiProvider> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(_baseUrlMeta,
          baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta));
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('key_ref')) {
      context.handle(_keyRefMeta,
          keyRef.isAcceptableOrUnknown(data['key_ref']!, _keyRefMeta));
    } else if (isInserting) {
      context.missing(_keyRefMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiProvider map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiProvider(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      baseUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_url'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      keyRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_ref'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AiProvidersTable createAlias(String alias) {
    return $AiProvidersTable(attachedDatabase, alias);
  }
}

class AiProvider extends DataClass implements Insertable<AiProvider> {
  final String id;
  final String name;
  final String baseUrl;
  final String model;
  final String keyRef;
  final bool isDefault;
  final DateTime createdAt;
  const AiProvider(
      {required this.id,
      required this.name,
      required this.baseUrl,
      required this.model,
      required this.keyRef,
      required this.isDefault,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_url'] = Variable<String>(baseUrl);
    map['model'] = Variable<String>(model);
    map['key_ref'] = Variable<String>(keyRef);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiProvidersCompanion toCompanion(bool nullToAbsent) {
    return AiProvidersCompanion(
      id: Value(id),
      name: Value(name),
      baseUrl: Value(baseUrl),
      model: Value(model),
      keyRef: Value(keyRef),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
    );
  }

  factory AiProvider.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiProvider(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      model: serializer.fromJson<String>(json['model']),
      keyRef: serializer.fromJson<String>(json['keyRef']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'model': serializer.toJson<String>(model),
      'keyRef': serializer.toJson<String>(keyRef),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiProvider copyWith(
          {String? id,
          String? name,
          String? baseUrl,
          String? model,
          String? keyRef,
          bool? isDefault,
          DateTime? createdAt}) =>
      AiProvider(
        id: id ?? this.id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        keyRef: keyRef ?? this.keyRef,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
      );
  AiProvider copyWithCompanion(AiProvidersCompanion data) {
    return AiProvider(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      model: data.model.present ? data.model.value : this.model,
      keyRef: data.keyRef.present ? data.keyRef.value : this.keyRef,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiProvider(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('model: $model, ')
          ..write('keyRef: $keyRef, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, baseUrl, model, keyRef, isDefault, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiProvider &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseUrl == this.baseUrl &&
          other.model == this.model &&
          other.keyRef == this.keyRef &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt);
}

class AiProvidersCompanion extends UpdateCompanion<AiProvider> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseUrl;
  final Value<String> model;
  final Value<String> keyRef;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AiProvidersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.model = const Value.absent(),
    this.keyRef = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiProvidersCompanion.insert({
    required String id,
    required String name,
    required String baseUrl,
    required String model,
    required String keyRef,
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        baseUrl = Value(baseUrl),
        model = Value(model),
        keyRef = Value(keyRef),
        createdAt = Value(createdAt);
  static Insertable<AiProvider> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseUrl,
    Expression<String>? model,
    Expression<String>? keyRef,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseUrl != null) 'base_url': baseUrl,
      if (model != null) 'model': model,
      if (keyRef != null) 'key_ref': keyRef,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiProvidersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? baseUrl,
      Value<String>? model,
      Value<String>? keyRef,
      Value<bool>? isDefault,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AiProvidersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      keyRef: keyRef ?? this.keyRef,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (keyRef.present) {
      map['key_ref'] = Variable<String>(keyRef.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiProvidersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('model: $model, ')
          ..write('keyRef: $keyRef, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiCallLogsTable extends AiCallLogs
    with TableInfo<$AiCallLogsTable, AiCallLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiCallLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _purposeMeta =
      const VerificationMeta('purpose');
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
      'purpose', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestBodyMeta =
      const VerificationMeta('requestBody');
  @override
  late final GeneratedColumn<String> requestBody = GeneratedColumn<String>(
      'request_body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _responseBodyMeta =
      const VerificationMeta('responseBody');
  @override
  late final GeneratedColumn<String> responseBody = GeneratedColumn<String>(
      'response_body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _httpStatusMeta =
      const VerificationMeta('httpStatus');
  @override
  late final GeneratedColumn<int> httpStatus = GeneratedColumn<int>(
      'http_status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _successMeta =
      const VerificationMeta('success');
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
      'success', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("success" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _errorTierMeta =
      const VerificationMeta('errorTier');
  @override
  late final GeneratedColumn<String> errorTier = GeneratedColumn<String>(
      'error_tier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
      'at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        purpose,
        requestBody,
        responseBody,
        httpStatus,
        success,
        errorTier,
        durationMs,
        at
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_call_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AiCallLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('purpose')) {
      context.handle(_purposeMeta,
          purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta));
    } else if (isInserting) {
      context.missing(_purposeMeta);
    }
    if (data.containsKey('request_body')) {
      context.handle(
          _requestBodyMeta,
          requestBody.isAcceptableOrUnknown(
              data['request_body']!, _requestBodyMeta));
    } else if (isInserting) {
      context.missing(_requestBodyMeta);
    }
    if (data.containsKey('response_body')) {
      context.handle(
          _responseBodyMeta,
          responseBody.isAcceptableOrUnknown(
              data['response_body']!, _responseBodyMeta));
    } else if (isInserting) {
      context.missing(_responseBodyMeta);
    }
    if (data.containsKey('http_status')) {
      context.handle(
          _httpStatusMeta,
          httpStatus.isAcceptableOrUnknown(
              data['http_status']!, _httpStatusMeta));
    }
    if (data.containsKey('success')) {
      context.handle(_successMeta,
          success.isAcceptableOrUnknown(data['success']!, _successMeta));
    }
    if (data.containsKey('error_tier')) {
      context.handle(_errorTierMeta,
          errorTier.isAcceptableOrUnknown(data['error_tier']!, _errorTierMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiCallLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiCallLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      purpose: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purpose'])!,
      requestBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_body'])!,
      responseBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response_body'])!,
      httpStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}http_status'])!,
      success: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}success'])!,
      errorTier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_tier']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      at: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
    );
  }

  @override
  $AiCallLogsTable createAlias(String alias) {
    return $AiCallLogsTable(attachedDatabase, alias);
  }
}

class AiCallLog extends DataClass implements Insertable<AiCallLog> {
  final int id;
  final String purpose;
  final String requestBody;
  final String responseBody;
  final int httpStatus;
  final bool success;
  final String? errorTier;
  final int durationMs;
  final DateTime at;
  const AiCallLog(
      {required this.id,
      required this.purpose,
      required this.requestBody,
      required this.responseBody,
      required this.httpStatus,
      required this.success,
      this.errorTier,
      required this.durationMs,
      required this.at});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['purpose'] = Variable<String>(purpose);
    map['request_body'] = Variable<String>(requestBody);
    map['response_body'] = Variable<String>(responseBody);
    map['http_status'] = Variable<int>(httpStatus);
    map['success'] = Variable<bool>(success);
    if (!nullToAbsent || errorTier != null) {
      map['error_tier'] = Variable<String>(errorTier);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  AiCallLogsCompanion toCompanion(bool nullToAbsent) {
    return AiCallLogsCompanion(
      id: Value(id),
      purpose: Value(purpose),
      requestBody: Value(requestBody),
      responseBody: Value(responseBody),
      httpStatus: Value(httpStatus),
      success: Value(success),
      errorTier: errorTier == null && nullToAbsent
          ? const Value.absent()
          : Value(errorTier),
      durationMs: Value(durationMs),
      at: Value(at),
    );
  }

  factory AiCallLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiCallLog(
      id: serializer.fromJson<int>(json['id']),
      purpose: serializer.fromJson<String>(json['purpose']),
      requestBody: serializer.fromJson<String>(json['requestBody']),
      responseBody: serializer.fromJson<String>(json['responseBody']),
      httpStatus: serializer.fromJson<int>(json['httpStatus']),
      success: serializer.fromJson<bool>(json['success']),
      errorTier: serializer.fromJson<String?>(json['errorTier']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'purpose': serializer.toJson<String>(purpose),
      'requestBody': serializer.toJson<String>(requestBody),
      'responseBody': serializer.toJson<String>(responseBody),
      'httpStatus': serializer.toJson<int>(httpStatus),
      'success': serializer.toJson<bool>(success),
      'errorTier': serializer.toJson<String?>(errorTier),
      'durationMs': serializer.toJson<int>(durationMs),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  AiCallLog copyWith(
          {int? id,
          String? purpose,
          String? requestBody,
          String? responseBody,
          int? httpStatus,
          bool? success,
          Value<String?> errorTier = const Value.absent(),
          int? durationMs,
          DateTime? at}) =>
      AiCallLog(
        id: id ?? this.id,
        purpose: purpose ?? this.purpose,
        requestBody: requestBody ?? this.requestBody,
        responseBody: responseBody ?? this.responseBody,
        httpStatus: httpStatus ?? this.httpStatus,
        success: success ?? this.success,
        errorTier: errorTier.present ? errorTier.value : this.errorTier,
        durationMs: durationMs ?? this.durationMs,
        at: at ?? this.at,
      );
  AiCallLog copyWithCompanion(AiCallLogsCompanion data) {
    return AiCallLog(
      id: data.id.present ? data.id.value : this.id,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      requestBody:
          data.requestBody.present ? data.requestBody.value : this.requestBody,
      responseBody: data.responseBody.present
          ? data.responseBody.value
          : this.responseBody,
      httpStatus:
          data.httpStatus.present ? data.httpStatus.value : this.httpStatus,
      success: data.success.present ? data.success.value : this.success,
      errorTier: data.errorTier.present ? data.errorTier.value : this.errorTier,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiCallLog(')
          ..write('id: $id, ')
          ..write('purpose: $purpose, ')
          ..write('requestBody: $requestBody, ')
          ..write('responseBody: $responseBody, ')
          ..write('httpStatus: $httpStatus, ')
          ..write('success: $success, ')
          ..write('errorTier: $errorTier, ')
          ..write('durationMs: $durationMs, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, purpose, requestBody, responseBody,
      httpStatus, success, errorTier, durationMs, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiCallLog &&
          other.id == this.id &&
          other.purpose == this.purpose &&
          other.requestBody == this.requestBody &&
          other.responseBody == this.responseBody &&
          other.httpStatus == this.httpStatus &&
          other.success == this.success &&
          other.errorTier == this.errorTier &&
          other.durationMs == this.durationMs &&
          other.at == this.at);
}

class AiCallLogsCompanion extends UpdateCompanion<AiCallLog> {
  final Value<int> id;
  final Value<String> purpose;
  final Value<String> requestBody;
  final Value<String> responseBody;
  final Value<int> httpStatus;
  final Value<bool> success;
  final Value<String?> errorTier;
  final Value<int> durationMs;
  final Value<DateTime> at;
  const AiCallLogsCompanion({
    this.id = const Value.absent(),
    this.purpose = const Value.absent(),
    this.requestBody = const Value.absent(),
    this.responseBody = const Value.absent(),
    this.httpStatus = const Value.absent(),
    this.success = const Value.absent(),
    this.errorTier = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.at = const Value.absent(),
  });
  AiCallLogsCompanion.insert({
    this.id = const Value.absent(),
    required String purpose,
    required String requestBody,
    required String responseBody,
    this.httpStatus = const Value.absent(),
    this.success = const Value.absent(),
    this.errorTier = const Value.absent(),
    this.durationMs = const Value.absent(),
    required DateTime at,
  })  : purpose = Value(purpose),
        requestBody = Value(requestBody),
        responseBody = Value(responseBody),
        at = Value(at);
  static Insertable<AiCallLog> custom({
    Expression<int>? id,
    Expression<String>? purpose,
    Expression<String>? requestBody,
    Expression<String>? responseBody,
    Expression<int>? httpStatus,
    Expression<bool>? success,
    Expression<String>? errorTier,
    Expression<int>? durationMs,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purpose != null) 'purpose': purpose,
      if (requestBody != null) 'request_body': requestBody,
      if (responseBody != null) 'response_body': responseBody,
      if (httpStatus != null) 'http_status': httpStatus,
      if (success != null) 'success': success,
      if (errorTier != null) 'error_tier': errorTier,
      if (durationMs != null) 'duration_ms': durationMs,
      if (at != null) 'at': at,
    });
  }

  AiCallLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? purpose,
      Value<String>? requestBody,
      Value<String>? responseBody,
      Value<int>? httpStatus,
      Value<bool>? success,
      Value<String?>? errorTier,
      Value<int>? durationMs,
      Value<DateTime>? at}) {
    return AiCallLogsCompanion(
      id: id ?? this.id,
      purpose: purpose ?? this.purpose,
      requestBody: requestBody ?? this.requestBody,
      responseBody: responseBody ?? this.responseBody,
      httpStatus: httpStatus ?? this.httpStatus,
      success: success ?? this.success,
      errorTier: errorTier ?? this.errorTier,
      durationMs: durationMs ?? this.durationMs,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (requestBody.present) {
      map['request_body'] = Variable<String>(requestBody.value);
    }
    if (responseBody.present) {
      map['response_body'] = Variable<String>(responseBody.value);
    }
    if (httpStatus.present) {
      map['http_status'] = Variable<int>(httpStatus.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (errorTier.present) {
      map['error_tier'] = Variable<String>(errorTier.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiCallLogsCompanion(')
          ..write('id: $id, ')
          ..write('purpose: $purpose, ')
          ..write('requestBody: $requestBody, ')
          ..write('responseBody: $responseBody, ')
          ..write('httpStatus: $httpStatus, ')
          ..write('success: $success, ')
          ..write('errorTier: $errorTier, ')
          ..write('durationMs: $durationMs, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestionRecordsTable questionRecords =
      $QuestionRecordsTable(this);
  late final $QuestionBankTable questionBank = $QuestionBankTable(this);
  late final $AnalysisJobsTable analysisJobs = $AnalysisJobsTable(this);
  late final $KnowledgePointsTable knowledgePoints =
      $KnowledgePointsTable(this);
  late final $QuestionKnowledgeLinksTable questionKnowledgeLinks =
      $QuestionKnowledgeLinksTable(this);
  late final $ReviewCardsTable reviewCards = $ReviewCardsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $GeneratedExercisesTable generatedExercises =
      $GeneratedExercisesTable(this);
  late final $AiMessagesTable aiMessages = $AiMessagesTable(this);
  late final $LearningEventsTable learningEvents = $LearningEventsTable(this);
  late final $GrowthMetricsTable growthMetrics = $GrowthMetricsTable(this);
  late final $AiProvidersTable aiProviders = $AiProvidersTable(this);
  late final $AiCallLogsTable aiCallLogs = $AiCallLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        questionRecords,
        questionBank,
        analysisJobs,
        knowledgePoints,
        questionKnowledgeLinks,
        reviewCards,
        reviewLogs,
        generatedExercises,
        aiMessages,
        learningEvents,
        growthMetrics,
        aiProviders,
        aiCallLogs
      ];
}

typedef $$QuestionRecordsTableCreateCompanionBuilder = QuestionRecordsCompanion
    Function({
  required String id,
  Value<String> subject,
  Value<String?> imagePath,
  Value<String> stem,
  Value<String?> answer,
  Value<String?> keySteps,
  Value<String?> errorCause,
  Value<String?> analysisDetail,
  Value<String> tags,
  Value<String> source,
  Value<String> contentStatus,
  Value<int> masteryLevel,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$QuestionRecordsTableUpdateCompanionBuilder = QuestionRecordsCompanion
    Function({
  Value<String> id,
  Value<String> subject,
  Value<String?> imagePath,
  Value<String> stem,
  Value<String?> answer,
  Value<String?> keySteps,
  Value<String?> errorCause,
  Value<String?> analysisDetail,
  Value<String> tags,
  Value<String> source,
  Value<String> contentStatus,
  Value<int> masteryLevel,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$QuestionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stem => $composableBuilder(
      column: $table.stem, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keySteps => $composableBuilder(
      column: $table.keySteps, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorCause => $composableBuilder(
      column: $table.errorCause, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get analysisDetail => $composableBuilder(
      column: $table.analysisDetail,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$QuestionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stem => $composableBuilder(
      column: $table.stem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keySteps => $composableBuilder(
      column: $table.keySteps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorCause => $composableBuilder(
      column: $table.errorCause, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get analysisDetail => $composableBuilder(
      column: $table.analysisDetail,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuestionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get stem =>
      $composableBuilder(column: $table.stem, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get keySteps =>
      $composableBuilder(column: $table.keySteps, builder: (column) => column);

  GeneratedColumn<String> get errorCause => $composableBuilder(
      column: $table.errorCause, builder: (column) => column);

  GeneratedColumn<String> get analysisDetail => $composableBuilder(
      column: $table.analysisDetail, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus, builder: (column) => column);

  GeneratedColumn<int> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuestionRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionRecordsTable,
    QuestionRecord,
    $$QuestionRecordsTableFilterComposer,
    $$QuestionRecordsTableOrderingComposer,
    $$QuestionRecordsTableAnnotationComposer,
    $$QuestionRecordsTableCreateCompanionBuilder,
    $$QuestionRecordsTableUpdateCompanionBuilder,
    (
      QuestionRecord,
      BaseReferences<_$AppDatabase, $QuestionRecordsTable, QuestionRecord>
    ),
    QuestionRecord,
    PrefetchHooks Function()> {
  $$QuestionRecordsTableTableManager(
      _$AppDatabase db, $QuestionRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String> stem = const Value.absent(),
            Value<String?> answer = const Value.absent(),
            Value<String?> keySteps = const Value.absent(),
            Value<String?> errorCause = const Value.absent(),
            Value<String?> analysisDetail = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> contentStatus = const Value.absent(),
            Value<int> masteryLevel = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionRecordsCompanion(
            id: id,
            subject: subject,
            imagePath: imagePath,
            stem: stem,
            answer: answer,
            keySteps: keySteps,
            errorCause: errorCause,
            analysisDetail: analysisDetail,
            tags: tags,
            source: source,
            contentStatus: contentStatus,
            masteryLevel: masteryLevel,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> subject = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String> stem = const Value.absent(),
            Value<String?> answer = const Value.absent(),
            Value<String?> keySteps = const Value.absent(),
            Value<String?> errorCause = const Value.absent(),
            Value<String?> analysisDetail = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> contentStatus = const Value.absent(),
            Value<int> masteryLevel = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionRecordsCompanion.insert(
            id: id,
            subject: subject,
            imagePath: imagePath,
            stem: stem,
            answer: answer,
            keySteps: keySteps,
            errorCause: errorCause,
            analysisDetail: analysisDetail,
            tags: tags,
            source: source,
            contentStatus: contentStatus,
            masteryLevel: masteryLevel,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuestionRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionRecordsTable,
    QuestionRecord,
    $$QuestionRecordsTableFilterComposer,
    $$QuestionRecordsTableOrderingComposer,
    $$QuestionRecordsTableAnnotationComposer,
    $$QuestionRecordsTableCreateCompanionBuilder,
    $$QuestionRecordsTableUpdateCompanionBuilder,
    (
      QuestionRecord,
      BaseReferences<_$AppDatabase, $QuestionRecordsTable, QuestionRecord>
    ),
    QuestionRecord,
    PrefetchHooks Function()>;
typedef $$QuestionBankTableCreateCompanionBuilder = QuestionBankCompanion
    Function({
  required String id,
  Value<String?> sourceQuestionId,
  Value<String?> knowledgePointId,
  Value<String> subject,
  Value<String> questionType,
  Value<String> difficulty,
  required String content,
  required String kind,
  required String sourceLabel,
  Value<String?> sourceCitation,
  Value<int> usedCount,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$QuestionBankTableUpdateCompanionBuilder = QuestionBankCompanion
    Function({
  Value<String> id,
  Value<String?> sourceQuestionId,
  Value<String?> knowledgePointId,
  Value<String> subject,
  Value<String> questionType,
  Value<String> difficulty,
  Value<String> content,
  Value<String> kind,
  Value<String> sourceLabel,
  Value<String?> sourceCitation,
  Value<int> usedCount,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$QuestionBankTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionBankTable> {
  $$QuestionBankTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceQuestionId => $composableBuilder(
      column: $table.sourceQuestionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get knowledgePointId => $composableBuilder(
      column: $table.knowledgePointId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionType => $composableBuilder(
      column: $table.questionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceLabel => $composableBuilder(
      column: $table.sourceLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceCitation => $composableBuilder(
      column: $table.sourceCitation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usedCount => $composableBuilder(
      column: $table.usedCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$QuestionBankTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionBankTable> {
  $$QuestionBankTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceQuestionId => $composableBuilder(
      column: $table.sourceQuestionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get knowledgePointId => $composableBuilder(
      column: $table.knowledgePointId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionType => $composableBuilder(
      column: $table.questionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceLabel => $composableBuilder(
      column: $table.sourceLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceCitation => $composableBuilder(
      column: $table.sourceCitation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usedCount => $composableBuilder(
      column: $table.usedCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$QuestionBankTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionBankTable> {
  $$QuestionBankTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceQuestionId => $composableBuilder(
      column: $table.sourceQuestionId, builder: (column) => column);

  GeneratedColumn<String> get knowledgePointId => $composableBuilder(
      column: $table.knowledgePointId, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get questionType => $composableBuilder(
      column: $table.questionType, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get sourceLabel => $composableBuilder(
      column: $table.sourceLabel, builder: (column) => column);

  GeneratedColumn<String> get sourceCitation => $composableBuilder(
      column: $table.sourceCitation, builder: (column) => column);

  GeneratedColumn<int> get usedCount =>
      $composableBuilder(column: $table.usedCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QuestionBankTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionBankTable,
    QuestionBankData,
    $$QuestionBankTableFilterComposer,
    $$QuestionBankTableOrderingComposer,
    $$QuestionBankTableAnnotationComposer,
    $$QuestionBankTableCreateCompanionBuilder,
    $$QuestionBankTableUpdateCompanionBuilder,
    (
      QuestionBankData,
      BaseReferences<_$AppDatabase, $QuestionBankTable, QuestionBankData>
    ),
    QuestionBankData,
    PrefetchHooks Function()> {
  $$QuestionBankTableTableManager(_$AppDatabase db, $QuestionBankTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionBankTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionBankTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionBankTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> sourceQuestionId = const Value.absent(),
            Value<String?> knowledgePointId = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> questionType = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> sourceLabel = const Value.absent(),
            Value<String?> sourceCitation = const Value.absent(),
            Value<int> usedCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionBankCompanion(
            id: id,
            sourceQuestionId: sourceQuestionId,
            knowledgePointId: knowledgePointId,
            subject: subject,
            questionType: questionType,
            difficulty: difficulty,
            content: content,
            kind: kind,
            sourceLabel: sourceLabel,
            sourceCitation: sourceCitation,
            usedCount: usedCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> sourceQuestionId = const Value.absent(),
            Value<String?> knowledgePointId = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> questionType = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            required String content,
            required String kind,
            required String sourceLabel,
            Value<String?> sourceCitation = const Value.absent(),
            Value<int> usedCount = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionBankCompanion.insert(
            id: id,
            sourceQuestionId: sourceQuestionId,
            knowledgePointId: knowledgePointId,
            subject: subject,
            questionType: questionType,
            difficulty: difficulty,
            content: content,
            kind: kind,
            sourceLabel: sourceLabel,
            sourceCitation: sourceCitation,
            usedCount: usedCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuestionBankTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionBankTable,
    QuestionBankData,
    $$QuestionBankTableFilterComposer,
    $$QuestionBankTableOrderingComposer,
    $$QuestionBankTableAnnotationComposer,
    $$QuestionBankTableCreateCompanionBuilder,
    $$QuestionBankTableUpdateCompanionBuilder,
    (
      QuestionBankData,
      BaseReferences<_$AppDatabase, $QuestionBankTable, QuestionBankData>
    ),
    QuestionBankData,
    PrefetchHooks Function()>;
typedef $$AnalysisJobsTableCreateCompanionBuilder = AnalysisJobsCompanion
    Function({
  required String id,
  required String imagePath,
  Value<String> status,
  Value<String> splitResult,
  Value<String> results,
  Value<String?> error,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AnalysisJobsTableUpdateCompanionBuilder = AnalysisJobsCompanion
    Function({
  Value<String> id,
  Value<String> imagePath,
  Value<String> status,
  Value<String> splitResult,
  Value<String> results,
  Value<String?> error,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AnalysisJobsTableFilterComposer
    extends Composer<_$AppDatabase, $AnalysisJobsTable> {
  $$AnalysisJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get splitResult => $composableBuilder(
      column: $table.splitResult, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get results => $composableBuilder(
      column: $table.results, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AnalysisJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalysisJobsTable> {
  $$AnalysisJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get splitResult => $composableBuilder(
      column: $table.splitResult, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get results => $composableBuilder(
      column: $table.results, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AnalysisJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalysisJobsTable> {
  $$AnalysisJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get splitResult => $composableBuilder(
      column: $table.splitResult, builder: (column) => column);

  GeneratedColumn<String> get results =>
      $composableBuilder(column: $table.results, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AnalysisJobsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnalysisJobsTable,
    AnalysisJob,
    $$AnalysisJobsTableFilterComposer,
    $$AnalysisJobsTableOrderingComposer,
    $$AnalysisJobsTableAnnotationComposer,
    $$AnalysisJobsTableCreateCompanionBuilder,
    $$AnalysisJobsTableUpdateCompanionBuilder,
    (
      AnalysisJob,
      BaseReferences<_$AppDatabase, $AnalysisJobsTable, AnalysisJob>
    ),
    AnalysisJob,
    PrefetchHooks Function()> {
  $$AnalysisJobsTableTableManager(_$AppDatabase db, $AnalysisJobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalysisJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalysisJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalysisJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> splitResult = const Value.absent(),
            Value<String> results = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalysisJobsCompanion(
            id: id,
            imagePath: imagePath,
            status: status,
            splitResult: splitResult,
            results: results,
            error: error,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String imagePath,
            Value<String> status = const Value.absent(),
            Value<String> splitResult = const Value.absent(),
            Value<String> results = const Value.absent(),
            Value<String?> error = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalysisJobsCompanion.insert(
            id: id,
            imagePath: imagePath,
            status: status,
            splitResult: splitResult,
            results: results,
            error: error,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnalysisJobsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnalysisJobsTable,
    AnalysisJob,
    $$AnalysisJobsTableFilterComposer,
    $$AnalysisJobsTableOrderingComposer,
    $$AnalysisJobsTableAnnotationComposer,
    $$AnalysisJobsTableCreateCompanionBuilder,
    $$AnalysisJobsTableUpdateCompanionBuilder,
    (
      AnalysisJob,
      BaseReferences<_$AppDatabase, $AnalysisJobsTable, AnalysisJob>
    ),
    AnalysisJob,
    PrefetchHooks Function()>;
typedef $$KnowledgePointsTableCreateCompanionBuilder = KnowledgePointsCompanion
    Function({
  required String id,
  Value<String> subject,
  Value<String> version,
  Value<String> book,
  Value<String> chapter,
  Value<String> lesson,
  required String name,
  required DateTime firstSeenAt,
  Value<int> rowid,
});
typedef $$KnowledgePointsTableUpdateCompanionBuilder = KnowledgePointsCompanion
    Function({
  Value<String> id,
  Value<String> subject,
  Value<String> version,
  Value<String> book,
  Value<String> chapter,
  Value<String> lesson,
  Value<String> name,
  Value<DateTime> firstSeenAt,
  Value<int> rowid,
});

class $$KnowledgePointsTableFilterComposer
    extends Composer<_$AppDatabase, $KnowledgePointsTable> {
  $$KnowledgePointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get book => $composableBuilder(
      column: $table.book, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapter => $composableBuilder(
      column: $table.chapter, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lesson => $composableBuilder(
      column: $table.lesson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firstSeenAt => $composableBuilder(
      column: $table.firstSeenAt, builder: (column) => ColumnFilters(column));
}

class $$KnowledgePointsTableOrderingComposer
    extends Composer<_$AppDatabase, $KnowledgePointsTable> {
  $$KnowledgePointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get book => $composableBuilder(
      column: $table.book, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapter => $composableBuilder(
      column: $table.chapter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lesson => $composableBuilder(
      column: $table.lesson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firstSeenAt => $composableBuilder(
      column: $table.firstSeenAt, builder: (column) => ColumnOrderings(column));
}

class $$KnowledgePointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KnowledgePointsTable> {
  $$KnowledgePointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<String> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get lesson =>
      $composableBuilder(column: $table.lesson, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeenAt => $composableBuilder(
      column: $table.firstSeenAt, builder: (column) => column);
}

class $$KnowledgePointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KnowledgePointsTable,
    KnowledgePoint,
    $$KnowledgePointsTableFilterComposer,
    $$KnowledgePointsTableOrderingComposer,
    $$KnowledgePointsTableAnnotationComposer,
    $$KnowledgePointsTableCreateCompanionBuilder,
    $$KnowledgePointsTableUpdateCompanionBuilder,
    (
      KnowledgePoint,
      BaseReferences<_$AppDatabase, $KnowledgePointsTable, KnowledgePoint>
    ),
    KnowledgePoint,
    PrefetchHooks Function()> {
  $$KnowledgePointsTableTableManager(
      _$AppDatabase db, $KnowledgePointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnowledgePointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnowledgePointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnowledgePointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> version = const Value.absent(),
            Value<String> book = const Value.absent(),
            Value<String> chapter = const Value.absent(),
            Value<String> lesson = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> firstSeenAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KnowledgePointsCompanion(
            id: id,
            subject: subject,
            version: version,
            book: book,
            chapter: chapter,
            lesson: lesson,
            name: name,
            firstSeenAt: firstSeenAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> subject = const Value.absent(),
            Value<String> version = const Value.absent(),
            Value<String> book = const Value.absent(),
            Value<String> chapter = const Value.absent(),
            Value<String> lesson = const Value.absent(),
            required String name,
            required DateTime firstSeenAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              KnowledgePointsCompanion.insert(
            id: id,
            subject: subject,
            version: version,
            book: book,
            chapter: chapter,
            lesson: lesson,
            name: name,
            firstSeenAt: firstSeenAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KnowledgePointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KnowledgePointsTable,
    KnowledgePoint,
    $$KnowledgePointsTableFilterComposer,
    $$KnowledgePointsTableOrderingComposer,
    $$KnowledgePointsTableAnnotationComposer,
    $$KnowledgePointsTableCreateCompanionBuilder,
    $$KnowledgePointsTableUpdateCompanionBuilder,
    (
      KnowledgePoint,
      BaseReferences<_$AppDatabase, $KnowledgePointsTable, KnowledgePoint>
    ),
    KnowledgePoint,
    PrefetchHooks Function()>;
typedef $$QuestionKnowledgeLinksTableCreateCompanionBuilder
    = QuestionKnowledgeLinksCompanion Function({
  Value<int> id,
  required String questionId,
  required String knowledgePointId,
});
typedef $$QuestionKnowledgeLinksTableUpdateCompanionBuilder
    = QuestionKnowledgeLinksCompanion Function({
  Value<int> id,
  Value<String> questionId,
  Value<String> knowledgePointId,
});

class $$QuestionKnowledgeLinksTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionKnowledgeLinksTable> {
  $$QuestionKnowledgeLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get knowledgePointId => $composableBuilder(
      column: $table.knowledgePointId,
      builder: (column) => ColumnFilters(column));
}

class $$QuestionKnowledgeLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionKnowledgeLinksTable> {
  $$QuestionKnowledgeLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get knowledgePointId => $composableBuilder(
      column: $table.knowledgePointId,
      builder: (column) => ColumnOrderings(column));
}

class $$QuestionKnowledgeLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionKnowledgeLinksTable> {
  $$QuestionKnowledgeLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<String> get knowledgePointId => $composableBuilder(
      column: $table.knowledgePointId, builder: (column) => column);
}

class $$QuestionKnowledgeLinksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionKnowledgeLinksTable,
    QuestionKnowledgeLink,
    $$QuestionKnowledgeLinksTableFilterComposer,
    $$QuestionKnowledgeLinksTableOrderingComposer,
    $$QuestionKnowledgeLinksTableAnnotationComposer,
    $$QuestionKnowledgeLinksTableCreateCompanionBuilder,
    $$QuestionKnowledgeLinksTableUpdateCompanionBuilder,
    (
      QuestionKnowledgeLink,
      BaseReferences<_$AppDatabase, $QuestionKnowledgeLinksTable,
          QuestionKnowledgeLink>
    ),
    QuestionKnowledgeLink,
    PrefetchHooks Function()> {
  $$QuestionKnowledgeLinksTableTableManager(
      _$AppDatabase db, $QuestionKnowledgeLinksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionKnowledgeLinksTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionKnowledgeLinksTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionKnowledgeLinksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<String> knowledgePointId = const Value.absent(),
          }) =>
              QuestionKnowledgeLinksCompanion(
            id: id,
            questionId: questionId,
            knowledgePointId: knowledgePointId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String questionId,
            required String knowledgePointId,
          }) =>
              QuestionKnowledgeLinksCompanion.insert(
            id: id,
            questionId: questionId,
            knowledgePointId: knowledgePointId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuestionKnowledgeLinksTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $QuestionKnowledgeLinksTable,
        QuestionKnowledgeLink,
        $$QuestionKnowledgeLinksTableFilterComposer,
        $$QuestionKnowledgeLinksTableOrderingComposer,
        $$QuestionKnowledgeLinksTableAnnotationComposer,
        $$QuestionKnowledgeLinksTableCreateCompanionBuilder,
        $$QuestionKnowledgeLinksTableUpdateCompanionBuilder,
        (
          QuestionKnowledgeLink,
          BaseReferences<_$AppDatabase, $QuestionKnowledgeLinksTable,
              QuestionKnowledgeLink>
        ),
        QuestionKnowledgeLink,
        PrefetchHooks Function()>;
typedef $$ReviewCardsTableCreateCompanionBuilder = ReviewCardsCompanion
    Function({
  required String id,
  required String questionId,
  required DateTime due,
  Value<int> state,
  Value<int?> step,
  Value<double> stability,
  Value<double> difficulty,
  Value<double> easinessFactor,
  Value<int> intervalDays,
  Value<int> reps,
  Value<int> lapses,
  Value<DateTime?> lastReviewAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ReviewCardsTableUpdateCompanionBuilder = ReviewCardsCompanion
    Function({
  Value<String> id,
  Value<String> questionId,
  Value<DateTime> due,
  Value<int> state,
  Value<int?> step,
  Value<double> stability,
  Value<double> difficulty,
  Value<double> easinessFactor,
  Value<int> intervalDays,
  Value<int> reps,
  Value<int> lapses,
  Value<DateTime?> lastReviewAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ReviewCardsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get due => $composableBuilder(
      column: $table.due, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get step => $composableBuilder(
      column: $table.step, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get easinessFactor => $composableBuilder(
      column: $table.easinessFactor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReviewAt => $composableBuilder(
      column: $table.lastReviewAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ReviewCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get due => $composableBuilder(
      column: $table.due, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get step => $composableBuilder(
      column: $table.step, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get easinessFactor => $composableBuilder(
      column: $table.easinessFactor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReviewAt => $composableBuilder(
      column: $table.lastReviewAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ReviewCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<double> get easinessFactor => $composableBuilder(
      column: $table.easinessFactor, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewAt => $composableBuilder(
      column: $table.lastReviewAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReviewCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReviewCardsTable,
    ReviewCard,
    $$ReviewCardsTableFilterComposer,
    $$ReviewCardsTableOrderingComposer,
    $$ReviewCardsTableAnnotationComposer,
    $$ReviewCardsTableCreateCompanionBuilder,
    $$ReviewCardsTableUpdateCompanionBuilder,
    (ReviewCard, BaseReferences<_$AppDatabase, $ReviewCardsTable, ReviewCard>),
    ReviewCard,
    PrefetchHooks Function()> {
  $$ReviewCardsTableTableManager(_$AppDatabase db, $ReviewCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<DateTime> due = const Value.absent(),
            Value<int> state = const Value.absent(),
            Value<int?> step = const Value.absent(),
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<double> easinessFactor = const Value.absent(),
            Value<int> intervalDays = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<DateTime?> lastReviewAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReviewCardsCompanion(
            id: id,
            questionId: questionId,
            due: due,
            state: state,
            step: step,
            stability: stability,
            difficulty: difficulty,
            easinessFactor: easinessFactor,
            intervalDays: intervalDays,
            reps: reps,
            lapses: lapses,
            lastReviewAt: lastReviewAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String questionId,
            required DateTime due,
            Value<int> state = const Value.absent(),
            Value<int?> step = const Value.absent(),
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<double> easinessFactor = const Value.absent(),
            Value<int> intervalDays = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<DateTime?> lastReviewAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReviewCardsCompanion.insert(
            id: id,
            questionId: questionId,
            due: due,
            state: state,
            step: step,
            stability: stability,
            difficulty: difficulty,
            easinessFactor: easinessFactor,
            intervalDays: intervalDays,
            reps: reps,
            lapses: lapses,
            lastReviewAt: lastReviewAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReviewCardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReviewCardsTable,
    ReviewCard,
    $$ReviewCardsTableFilterComposer,
    $$ReviewCardsTableOrderingComposer,
    $$ReviewCardsTableAnnotationComposer,
    $$ReviewCardsTableCreateCompanionBuilder,
    $$ReviewCardsTableUpdateCompanionBuilder,
    (ReviewCard, BaseReferences<_$AppDatabase, $ReviewCardsTable, ReviewCard>),
    ReviewCard,
    PrefetchHooks Function()>;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  required String questionId,
  required int rating,
  required DateTime reviewedAt,
  Value<int?> durationMs,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  Value<String> questionId,
  Value<int> rating,
  Value<DateTime> reviewedAt,
  Value<int?> durationMs,
});

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);
}

class $$ReviewLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReviewLogsTable,
    ReviewLog,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLog, BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog>),
    ReviewLog,
    PrefetchHooks Function()> {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<int> rating = const Value.absent(),
            Value<DateTime> reviewedAt = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
          }) =>
              ReviewLogsCompanion(
            id: id,
            questionId: questionId,
            rating: rating,
            reviewedAt: reviewedAt,
            durationMs: durationMs,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String questionId,
            required int rating,
            required DateTime reviewedAt,
            Value<int?> durationMs = const Value.absent(),
          }) =>
              ReviewLogsCompanion.insert(
            id: id,
            questionId: questionId,
            rating: rating,
            reviewedAt: reviewedAt,
            durationMs: durationMs,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReviewLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReviewLogsTable,
    ReviewLog,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLog, BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog>),
    ReviewLog,
    PrefetchHooks Function()>;
typedef $$GeneratedExercisesTableCreateCompanionBuilder
    = GeneratedExercisesCompanion Function({
  required String id,
  required String questionId,
  required String content,
  Value<String> status,
  required DateTime createdAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});
typedef $$GeneratedExercisesTableUpdateCompanionBuilder
    = GeneratedExercisesCompanion Function({
  Value<String> id,
  Value<String> questionId,
  Value<String> content,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});

class $$GeneratedExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$GeneratedExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$GeneratedExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$GeneratedExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GeneratedExercisesTable,
    GeneratedExercise,
    $$GeneratedExercisesTableFilterComposer,
    $$GeneratedExercisesTableOrderingComposer,
    $$GeneratedExercisesTableAnnotationComposer,
    $$GeneratedExercisesTableCreateCompanionBuilder,
    $$GeneratedExercisesTableUpdateCompanionBuilder,
    (
      GeneratedExercise,
      BaseReferences<_$AppDatabase, $GeneratedExercisesTable, GeneratedExercise>
    ),
    GeneratedExercise,
    PrefetchHooks Function()> {
  $$GeneratedExercisesTableTableManager(
      _$AppDatabase db, $GeneratedExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneratedExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneratedExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneratedExercisesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GeneratedExercisesCompanion(
            id: id,
            questionId: questionId,
            content: content,
            status: status,
            createdAt: createdAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String questionId,
            required String content,
            Value<String> status = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GeneratedExercisesCompanion.insert(
            id: id,
            questionId: questionId,
            content: content,
            status: status,
            createdAt: createdAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GeneratedExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GeneratedExercisesTable,
    GeneratedExercise,
    $$GeneratedExercisesTableFilterComposer,
    $$GeneratedExercisesTableOrderingComposer,
    $$GeneratedExercisesTableAnnotationComposer,
    $$GeneratedExercisesTableCreateCompanionBuilder,
    $$GeneratedExercisesTableUpdateCompanionBuilder,
    (
      GeneratedExercise,
      BaseReferences<_$AppDatabase, $GeneratedExercisesTable, GeneratedExercise>
    ),
    GeneratedExercise,
    PrefetchHooks Function()>;
typedef $$AiMessagesTableCreateCompanionBuilder = AiMessagesCompanion Function({
  Value<int> id,
  Value<String?> questionId,
  required String role,
  required String content,
  required DateTime createdAt,
});
typedef $$AiMessagesTableUpdateCompanionBuilder = AiMessagesCompanion Function({
  Value<int> id,
  Value<String?> questionId,
  Value<String> role,
  Value<String> content,
  Value<DateTime> createdAt,
});

class $$AiMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AiMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AiMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AiMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiMessagesTable,
    AiMessageRow,
    $$AiMessagesTableFilterComposer,
    $$AiMessagesTableOrderingComposer,
    $$AiMessagesTableAnnotationComposer,
    $$AiMessagesTableCreateCompanionBuilder,
    $$AiMessagesTableUpdateCompanionBuilder,
    (
      AiMessageRow,
      BaseReferences<_$AppDatabase, $AiMessagesTable, AiMessageRow>
    ),
    AiMessageRow,
    PrefetchHooks Function()> {
  $$AiMessagesTableTableManager(_$AppDatabase db, $AiMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> questionId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AiMessagesCompanion(
            id: id,
            questionId: questionId,
            role: role,
            content: content,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> questionId = const Value.absent(),
            required String role,
            required String content,
            required DateTime createdAt,
          }) =>
              AiMessagesCompanion.insert(
            id: id,
            questionId: questionId,
            role: role,
            content: content,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiMessagesTable,
    AiMessageRow,
    $$AiMessagesTableFilterComposer,
    $$AiMessagesTableOrderingComposer,
    $$AiMessagesTableAnnotationComposer,
    $$AiMessagesTableCreateCompanionBuilder,
    $$AiMessagesTableUpdateCompanionBuilder,
    (
      AiMessageRow,
      BaseReferences<_$AppDatabase, $AiMessagesTable, AiMessageRow>
    ),
    AiMessageRow,
    PrefetchHooks Function()>;
typedef $$LearningEventsTableCreateCompanionBuilder = LearningEventsCompanion
    Function({
  Value<int> id,
  required String eventType,
  Value<String?> questionId,
  required DateTime at,
  Value<String> payload,
});
typedef $$LearningEventsTableUpdateCompanionBuilder = LearningEventsCompanion
    Function({
  Value<int> id,
  Value<String> eventType,
  Value<String?> questionId,
  Value<DateTime> at,
  Value<String> payload,
});

class $$LearningEventsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningEventsTable> {
  $$LearningEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));
}

class $$LearningEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningEventsTable> {
  $$LearningEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));
}

class $$LearningEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningEventsTable> {
  $$LearningEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$LearningEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LearningEventsTable,
    LearningEvent,
    $$LearningEventsTableFilterComposer,
    $$LearningEventsTableOrderingComposer,
    $$LearningEventsTableAnnotationComposer,
    $$LearningEventsTableCreateCompanionBuilder,
    $$LearningEventsTableUpdateCompanionBuilder,
    (
      LearningEvent,
      BaseReferences<_$AppDatabase, $LearningEventsTable, LearningEvent>
    ),
    LearningEvent,
    PrefetchHooks Function()> {
  $$LearningEventsTableTableManager(
      _$AppDatabase db, $LearningEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String?> questionId = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String> payload = const Value.absent(),
          }) =>
              LearningEventsCompanion(
            id: id,
            eventType: eventType,
            questionId: questionId,
            at: at,
            payload: payload,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String eventType,
            Value<String?> questionId = const Value.absent(),
            required DateTime at,
            Value<String> payload = const Value.absent(),
          }) =>
              LearningEventsCompanion.insert(
            id: id,
            eventType: eventType,
            questionId: questionId,
            at: at,
            payload: payload,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LearningEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LearningEventsTable,
    LearningEvent,
    $$LearningEventsTableFilterComposer,
    $$LearningEventsTableOrderingComposer,
    $$LearningEventsTableAnnotationComposer,
    $$LearningEventsTableCreateCompanionBuilder,
    $$LearningEventsTableUpdateCompanionBuilder,
    (
      LearningEvent,
      BaseReferences<_$AppDatabase, $LearningEventsTable, LearningEvent>
    ),
    LearningEvent,
    PrefetchHooks Function()>;
typedef $$GrowthMetricsTableCreateCompanionBuilder = GrowthMetricsCompanion
    Function({
  required String date,
  Value<double> learningScore,
  Value<double> persistenceScore,
  Value<double> recoveryScore,
  Value<int> reviewDone,
  Value<int> reviewDue,
  Value<int> streak,
  Value<String> snapshotJson,
  Value<int> rowid,
});
typedef $$GrowthMetricsTableUpdateCompanionBuilder = GrowthMetricsCompanion
    Function({
  Value<String> date,
  Value<double> learningScore,
  Value<double> persistenceScore,
  Value<double> recoveryScore,
  Value<int> reviewDone,
  Value<int> reviewDue,
  Value<int> streak,
  Value<String> snapshotJson,
  Value<int> rowid,
});

class $$GrowthMetricsTableFilterComposer
    extends Composer<_$AppDatabase, $GrowthMetricsTable> {
  $$GrowthMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get learningScore => $composableBuilder(
      column: $table.learningScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get persistenceScore => $composableBuilder(
      column: $table.persistenceScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get recoveryScore => $composableBuilder(
      column: $table.recoveryScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewDone => $composableBuilder(
      column: $table.reviewDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewDue => $composableBuilder(
      column: $table.reviewDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get streak => $composableBuilder(
      column: $table.streak, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => ColumnFilters(column));
}

class $$GrowthMetricsTableOrderingComposer
    extends Composer<_$AppDatabase, $GrowthMetricsTable> {
  $$GrowthMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get learningScore => $composableBuilder(
      column: $table.learningScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get persistenceScore => $composableBuilder(
      column: $table.persistenceScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get recoveryScore => $composableBuilder(
      column: $table.recoveryScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewDone => $composableBuilder(
      column: $table.reviewDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewDue => $composableBuilder(
      column: $table.reviewDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get streak => $composableBuilder(
      column: $table.streak, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson,
      builder: (column) => ColumnOrderings(column));
}

class $$GrowthMetricsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrowthMetricsTable> {
  $$GrowthMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get learningScore => $composableBuilder(
      column: $table.learningScore, builder: (column) => column);

  GeneratedColumn<double> get persistenceScore => $composableBuilder(
      column: $table.persistenceScore, builder: (column) => column);

  GeneratedColumn<double> get recoveryScore => $composableBuilder(
      column: $table.recoveryScore, builder: (column) => column);

  GeneratedColumn<int> get reviewDone => $composableBuilder(
      column: $table.reviewDone, builder: (column) => column);

  GeneratedColumn<int> get reviewDue =>
      $composableBuilder(column: $table.reviewDue, builder: (column) => column);

  GeneratedColumn<int> get streak =>
      $composableBuilder(column: $table.streak, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => column);
}

class $$GrowthMetricsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GrowthMetricsTable,
    GrowthMetric,
    $$GrowthMetricsTableFilterComposer,
    $$GrowthMetricsTableOrderingComposer,
    $$GrowthMetricsTableAnnotationComposer,
    $$GrowthMetricsTableCreateCompanionBuilder,
    $$GrowthMetricsTableUpdateCompanionBuilder,
    (
      GrowthMetric,
      BaseReferences<_$AppDatabase, $GrowthMetricsTable, GrowthMetric>
    ),
    GrowthMetric,
    PrefetchHooks Function()> {
  $$GrowthMetricsTableTableManager(_$AppDatabase db, $GrowthMetricsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrowthMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrowthMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrowthMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<double> learningScore = const Value.absent(),
            Value<double> persistenceScore = const Value.absent(),
            Value<double> recoveryScore = const Value.absent(),
            Value<int> reviewDone = const Value.absent(),
            Value<int> reviewDue = const Value.absent(),
            Value<int> streak = const Value.absent(),
            Value<String> snapshotJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GrowthMetricsCompanion(
            date: date,
            learningScore: learningScore,
            persistenceScore: persistenceScore,
            recoveryScore: recoveryScore,
            reviewDone: reviewDone,
            reviewDue: reviewDue,
            streak: streak,
            snapshotJson: snapshotJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            Value<double> learningScore = const Value.absent(),
            Value<double> persistenceScore = const Value.absent(),
            Value<double> recoveryScore = const Value.absent(),
            Value<int> reviewDone = const Value.absent(),
            Value<int> reviewDue = const Value.absent(),
            Value<int> streak = const Value.absent(),
            Value<String> snapshotJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GrowthMetricsCompanion.insert(
            date: date,
            learningScore: learningScore,
            persistenceScore: persistenceScore,
            recoveryScore: recoveryScore,
            reviewDone: reviewDone,
            reviewDue: reviewDue,
            streak: streak,
            snapshotJson: snapshotJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GrowthMetricsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GrowthMetricsTable,
    GrowthMetric,
    $$GrowthMetricsTableFilterComposer,
    $$GrowthMetricsTableOrderingComposer,
    $$GrowthMetricsTableAnnotationComposer,
    $$GrowthMetricsTableCreateCompanionBuilder,
    $$GrowthMetricsTableUpdateCompanionBuilder,
    (
      GrowthMetric,
      BaseReferences<_$AppDatabase, $GrowthMetricsTable, GrowthMetric>
    ),
    GrowthMetric,
    PrefetchHooks Function()>;
typedef $$AiProvidersTableCreateCompanionBuilder = AiProvidersCompanion
    Function({
  required String id,
  required String name,
  required String baseUrl,
  required String model,
  required String keyRef,
  Value<bool> isDefault,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AiProvidersTableUpdateCompanionBuilder = AiProvidersCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> baseUrl,
  Value<String> model,
  Value<String> keyRef,
  Value<bool> isDefault,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AiProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $AiProvidersTable> {
  $$AiProvidersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyRef => $composableBuilder(
      column: $table.keyRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AiProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $AiProvidersTable> {
  $$AiProvidersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyRef => $composableBuilder(
      column: $table.keyRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AiProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiProvidersTable> {
  $$AiProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get keyRef =>
      $composableBuilder(column: $table.keyRef, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AiProvidersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiProvidersTable,
    AiProvider,
    $$AiProvidersTableFilterComposer,
    $$AiProvidersTableOrderingComposer,
    $$AiProvidersTableAnnotationComposer,
    $$AiProvidersTableCreateCompanionBuilder,
    $$AiProvidersTableUpdateCompanionBuilder,
    (AiProvider, BaseReferences<_$AppDatabase, $AiProvidersTable, AiProvider>),
    AiProvider,
    PrefetchHooks Function()> {
  $$AiProvidersTableTableManager(_$AppDatabase db, $AiProvidersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> baseUrl = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<String> keyRef = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiProvidersCompanion(
            id: id,
            name: name,
            baseUrl: baseUrl,
            model: model,
            keyRef: keyRef,
            isDefault: isDefault,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String baseUrl,
            required String model,
            required String keyRef,
            Value<bool> isDefault = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AiProvidersCompanion.insert(
            id: id,
            name: name,
            baseUrl: baseUrl,
            model: model,
            keyRef: keyRef,
            isDefault: isDefault,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiProvidersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiProvidersTable,
    AiProvider,
    $$AiProvidersTableFilterComposer,
    $$AiProvidersTableOrderingComposer,
    $$AiProvidersTableAnnotationComposer,
    $$AiProvidersTableCreateCompanionBuilder,
    $$AiProvidersTableUpdateCompanionBuilder,
    (AiProvider, BaseReferences<_$AppDatabase, $AiProvidersTable, AiProvider>),
    AiProvider,
    PrefetchHooks Function()>;
typedef $$AiCallLogsTableCreateCompanionBuilder = AiCallLogsCompanion Function({
  Value<int> id,
  required String purpose,
  required String requestBody,
  required String responseBody,
  Value<int> httpStatus,
  Value<bool> success,
  Value<String?> errorTier,
  Value<int> durationMs,
  required DateTime at,
});
typedef $$AiCallLogsTableUpdateCompanionBuilder = AiCallLogsCompanion Function({
  Value<int> id,
  Value<String> purpose,
  Value<String> requestBody,
  Value<String> responseBody,
  Value<int> httpStatus,
  Value<bool> success,
  Value<String?> errorTier,
  Value<int> durationMs,
  Value<DateTime> at,
});

class $$AiCallLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AiCallLogsTable> {
  $$AiCallLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestBody => $composableBuilder(
      column: $table.requestBody, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseBody => $composableBuilder(
      column: $table.responseBody, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get httpStatus => $composableBuilder(
      column: $table.httpStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get success => $composableBuilder(
      column: $table.success, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorTier => $composableBuilder(
      column: $table.errorTier, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnFilters(column));
}

class $$AiCallLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiCallLogsTable> {
  $$AiCallLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestBody => $composableBuilder(
      column: $table.requestBody, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseBody => $composableBuilder(
      column: $table.responseBody,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get httpStatus => $composableBuilder(
      column: $table.httpStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get success => $composableBuilder(
      column: $table.success, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorTier => $composableBuilder(
      column: $table.errorTier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnOrderings(column));
}

class $$AiCallLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiCallLogsTable> {
  $$AiCallLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get requestBody => $composableBuilder(
      column: $table.requestBody, builder: (column) => column);

  GeneratedColumn<String> get responseBody => $composableBuilder(
      column: $table.responseBody, builder: (column) => column);

  GeneratedColumn<int> get httpStatus => $composableBuilder(
      column: $table.httpStatus, builder: (column) => column);

  GeneratedColumn<bool> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<String> get errorTier =>
      $composableBuilder(column: $table.errorTier, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$AiCallLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiCallLogsTable,
    AiCallLog,
    $$AiCallLogsTableFilterComposer,
    $$AiCallLogsTableOrderingComposer,
    $$AiCallLogsTableAnnotationComposer,
    $$AiCallLogsTableCreateCompanionBuilder,
    $$AiCallLogsTableUpdateCompanionBuilder,
    (AiCallLog, BaseReferences<_$AppDatabase, $AiCallLogsTable, AiCallLog>),
    AiCallLog,
    PrefetchHooks Function()> {
  $$AiCallLogsTableTableManager(_$AppDatabase db, $AiCallLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiCallLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiCallLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiCallLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> purpose = const Value.absent(),
            Value<String> requestBody = const Value.absent(),
            Value<String> responseBody = const Value.absent(),
            Value<int> httpStatus = const Value.absent(),
            Value<bool> success = const Value.absent(),
            Value<String?> errorTier = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
          }) =>
              AiCallLogsCompanion(
            id: id,
            purpose: purpose,
            requestBody: requestBody,
            responseBody: responseBody,
            httpStatus: httpStatus,
            success: success,
            errorTier: errorTier,
            durationMs: durationMs,
            at: at,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String purpose,
            required String requestBody,
            required String responseBody,
            Value<int> httpStatus = const Value.absent(),
            Value<bool> success = const Value.absent(),
            Value<String?> errorTier = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            required DateTime at,
          }) =>
              AiCallLogsCompanion.insert(
            id: id,
            purpose: purpose,
            requestBody: requestBody,
            responseBody: responseBody,
            httpStatus: httpStatus,
            success: success,
            errorTier: errorTier,
            durationMs: durationMs,
            at: at,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiCallLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiCallLogsTable,
    AiCallLog,
    $$AiCallLogsTableFilterComposer,
    $$AiCallLogsTableOrderingComposer,
    $$AiCallLogsTableAnnotationComposer,
    $$AiCallLogsTableCreateCompanionBuilder,
    $$AiCallLogsTableUpdateCompanionBuilder,
    (AiCallLog, BaseReferences<_$AppDatabase, $AiCallLogsTable, AiCallLog>),
    AiCallLog,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestionRecordsTableTableManager get questionRecords =>
      $$QuestionRecordsTableTableManager(_db, _db.questionRecords);
  $$QuestionBankTableTableManager get questionBank =>
      $$QuestionBankTableTableManager(_db, _db.questionBank);
  $$AnalysisJobsTableTableManager get analysisJobs =>
      $$AnalysisJobsTableTableManager(_db, _db.analysisJobs);
  $$KnowledgePointsTableTableManager get knowledgePoints =>
      $$KnowledgePointsTableTableManager(_db, _db.knowledgePoints);
  $$QuestionKnowledgeLinksTableTableManager get questionKnowledgeLinks =>
      $$QuestionKnowledgeLinksTableTableManager(
          _db, _db.questionKnowledgeLinks);
  $$ReviewCardsTableTableManager get reviewCards =>
      $$ReviewCardsTableTableManager(_db, _db.reviewCards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$GeneratedExercisesTableTableManager get generatedExercises =>
      $$GeneratedExercisesTableTableManager(_db, _db.generatedExercises);
  $$AiMessagesTableTableManager get aiMessages =>
      $$AiMessagesTableTableManager(_db, _db.aiMessages);
  $$LearningEventsTableTableManager get learningEvents =>
      $$LearningEventsTableTableManager(_db, _db.learningEvents);
  $$GrowthMetricsTableTableManager get growthMetrics =>
      $$GrowthMetricsTableTableManager(_db, _db.growthMetrics);
  $$AiProvidersTableTableManager get aiProviders =>
      $$AiProvidersTableTableManager(_db, _db.aiProviders);
  $$AiCallLogsTableTableManager get aiCallLogs =>
      $$AiCallLogsTableTableManager(_db, _db.aiCallLogs);
}
