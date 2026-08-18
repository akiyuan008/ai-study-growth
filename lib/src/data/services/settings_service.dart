import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/app_database.dart';

/// 应用设置：深渊默认模式、监控白名单（prefs 持久化）
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;
  static const _abyssKey = 'focus.abyss_default';
  static const _whitelistKey = 'monitor.whitelist';

  /// 深渊模式作为默认选项
  bool get abyssDefault => _prefs.getBool(_abyssKey) ?? false;
  Future<void> setAbyssDefault(bool v) => _prefs.setBool(_abyssKey, v);

  /// 监控白名单：这些包名的前台切换不算分心
  List<String> get whitelist {
    final raw = _prefs.getStringList(_whitelistKey);
    return raw ?? const [];
  }

  Future<void> addWhitelist(String package) async {
    final list = whitelist.toList();
    final pkg = package.trim();
    if (pkg.isEmpty || list.contains(pkg)) return;
    list.add(pkg);
    await _prefs.setStringList(_whitelistKey, list);
  }

  Future<void> removeWhitelist(String package) async {
    final list = whitelist.toList()..remove(package);
    await _prefs.setStringList(_whitelistKey, list);
  }

  bool isWhitelisted(String package) => whitelist.contains(package);
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
      'focusSessions':
          (await db.select(db.focusSessions).get()).map((r) => r.toJson()),
      'missions': (await db.select(db.missions).get()).map((r) => r.toJson()),
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
