import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/app_database.dart';

/// 应用设置：通知、备份偏好（prefs 持久化）
/// v13：专注/深渊/监控/白名单已删除
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  // ---- 通知设置 ----
  static const _notifyReviewKey = 'notify.review_enabled';
  static const _reviewNotifyTimeKey = 'notify.review_time';

  /// 每日复习提醒开关
  bool get notifyReviewEnabled => _prefs.getBool(_notifyReviewKey) ?? false;
  Future<void> setNotifyReviewEnabled(bool v) =>
      _prefs.setBool(_notifyReviewKey, v);

  /// 提醒时间 HH:mm
  String get reviewNotifyTime =>
      _prefs.getString(_reviewNotifyTimeKey) ?? '09:00';
  Future<void> setReviewNotifyTime(String v) =>
      _prefs.setString(_reviewNotifyTimeKey, v);
}

/// 数据备份导出：全库序列化为 JSON 文件
abstract final class DataExporter {
  static Future<String> exportToJson(AppDatabase db) async {
    final data = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'questionRecords':
          (await db.select(db.questionRecords).get()).map((r) => r.toJson()),
      'knowledgePoints':
          (await db.select(db.knowledgePoints).get()).map((r) => r.toJson()),
      'reviewCards':
          (await db.select(db.reviewCards).get()).map((r) => r.toJson()),
      'reviewLogs':
          (await db.select(db.reviewLogs).get()).map((r) => r.toJson()),
      'generatedExercises':
          (await db.select(db.generatedExercises).get()).map((r) => r.toJson()),
      'learningEvents':
          (await db.select(db.learningEvents).get()).map((r) => r.toJson()),
      'growthMetrics':
          (await db.select(db.growthMetrics).get()).map((r) => r.toJson()),
    };

    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'))
      ..createSync(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(backupDir.path, 'backup_$stamp.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert({
      for (final e in data.entries)
        e.key: e.value is Iterable ? (e.value as Iterable).toList() : e.value,
    }));
    return file.path;
  }
}

/// 图片缓存清理：删除拍题图片目录 + Flutter 图片缓存
abstract final class ImageCacheCleaner {
  static Future<int> cleanCaptures() async {
    final dir = await getApplicationDocumentsDirectory();
    final captureDir = Directory(p.join(dir.path, 'captures'));
    var freed = 0;
    if (captureDir.existsSync()) {
      for (final entity in captureDir.listSync()) {
        if (entity is File) {
          freed += await entity.length();
        }
      }
      captureDir.deleteSync(recursive: true);
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    return freed;
  }
}
