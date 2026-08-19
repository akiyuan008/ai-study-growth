import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/local/app_database.dart';
import 'backup_channel.dart';
import 'crypto.dart';
import 'webdav_client.dart';

/// 备份状态仓储：通道配置（SP）+ 密码（secure storage）+ 脏标记/时间戳
class BackupStateRepository {
  BackupStateRepository(this._prefs, {FlutterSecureStorage? vault})
      : _vault = vault ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final SharedPreferences _prefs;
  final FlutterSecureStorage _vault;

  static const _configKey = 'backup.channel_config';
  static const _dirtyKey = 'backup.dirty';
  static const _lastKey = 'backup.last_at';
  static const _cellularKey = 'backup.allow_cellular';
  static const _passwordKey = 'backup.channel_password';

  // ---- 通道配置 ----
  BackupChannelConfig? loadConfig() {
    final raw = _prefs.getString(_configKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BackupChannelConfig(
        type: BackupChannelType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => BackupChannelType.localExport,
        ),
        serverUrl: (json['serverUrl'] ?? '').toString(),
        username: (json['username'] ?? '').toString(),
        keyRef: (json['keyRef'] ?? _passwordKey).toString(),
        encryptEnabled: json['encryptEnabled'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConfig(
    BackupChannelConfig config, {
    required String password,
  }) async {
    await _prefs.setString(
      _configKey,
      jsonEncode({
        'type': config.type.name,
        'serverUrl': config.serverUrl,
        'username': config.username,
        'keyRef': _passwordKey,
        'encryptEnabled': config.encryptEnabled,
      }),
    );
    if (password.isNotEmpty) {
      await _vault.write(key: _passwordKey, value: password);
    }
  }

  Future<String> loadPassword() async =>
      await _vault.read(key: _passwordKey) ?? '';

  // ---- 脏标记与时间戳 ----
  bool get isDirty => _prefs.getBool(_dirtyKey) ?? true;
  Future<void> markDirty() => _prefs.setBool(_dirtyKey, true);
  Future<void> clearDirty() => _prefs.setBool(_dirtyKey, false);

  DateTime? get lastBackupAt {
    final ms = _prefs.getInt(_lastKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastBackupAt(DateTime at) =>
      _prefs.setInt(_lastKey, at.millisecondsSinceEpoch);

  bool get allowCellular => _prefs.getBool(_cellularKey) ?? false;
  Future<void> setAllowCellular(bool v) => _prefs.setBool(_cellularKey, v);
}

/// 备份服务（Part 4）：打包 → 可选加密 → 三通道 WebDAV / local_export
class BackupService {
  BackupService({
    required AppDatabase Function() dbFactory,
    required BackupStateRepository state,
  })  : _dbFactory = dbFactory,
        _state = state;

  final AppDatabase Function() _dbFactory;
  final BackupStateRepository _state;

  static const _remoteDir = 'StudyGrowthBackup';
  static const _maxVersions = 3;

  /// 云端备份文件名前缀
  static const _backupPrefix = 'backup_';

  /// 打包：DB 一致性快照 + 错题图片 + manifest.json → zip 字节
  /// 严禁包含密钥：ai_providers 表从快照中清空（密钥本在 secure storage）
  Future<Uint8List> buildPackage({required DateTime now}) async {
    final dir = await getApplicationDocumentsDirectory();
    final workDir = Directory(p.join(dir.path, 'backup_tmp'))
      ..createSync(recursive: true);

    // 1) DB 一致性快照（SQLite VACUUM INTO，无需关库）
    final dbCopy = File(p.join(workDir.path, 'study_growth.db'));
    if (dbCopy.existsSync()) dbCopy.deleteSync();
    final db = _dbFactory();
    await db.customStatement("VACUUM INTO '${dbCopy.path}'");

    // 2) 从快照中清空密钥指针表（严禁密钥相关数据出设备）
    final tmpDb = AppDatabase.openFile(dbCopy.path);
    await tmpDb.delete(tmpDb.aiProviders).go();
    await tmpDb.close();

    // 3) manifest（不含任何密钥）
    final images = _collectImages(dir.path);
    final manifest = {
      'app': 'ai-study-growth',
      'format': 1,
      'createdAt': now.toIso8601String(),
      'dbFile': 'study_growth.db',
      'imageCount': images.length,
      'note': 'DB snapshot + question images. No secrets included.',
    };

    // 4) zip
    final archive = Archive();
    void addFile(String name, List<int> bytes) {
      archive.addFile(
        ArchiveFile(name, bytes.length, bytes)
          ..lastModTime = now.millisecondsSinceEpoch ~/ 1000,
      );
    }

    addFile('manifest.json',
        utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest)));
    addFile('study_growth.db', await dbCopy.readAsBytes());
    for (final img in images) {
      addFile(
        'images/${p.basename(img.path)}',
        await img.readAsBytes(),
      );
    }

    final zipped = ZipEncoder().encode(archive);
    // 清理临时目录
    try {
      workDir.deleteSync(recursive: true);
    } catch (_) {}
    return Uint8List.fromList(zipped ?? const []);
  }

  List<File> _collectImages(String docPath) {
    final captureDir = Directory(p.join(docPath, 'captures'));
    if (!captureDir.existsSync()) return const [];
    return captureDir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.jpeg') ||
            f.path.endsWith('.png'))
        .toList();
  }

  /// 立即备份（手动/自动共用）
  Future<({bool ok, String message})> backupNow() async {
    final config = _state.loadConfig();
    if (config == null) {
      return (ok: false, message: '请先配置备份通道');
    }
    final now = DateTime.now();
    try {
      var bytes = await buildPackage(now: now);
      final fileName =
          '$_backupPrefix${_stamp(now)}${config.encryptEnabled ? '.zip.enc' : '.zip'}';
      if (config.encryptEnabled) {
        final password = await _state.loadPassword();
        bytes = BackupCrypto.encrypt(bytes, password);
      }

      switch (config.type) {
        case BackupChannelType.localExport:
          final dir = await getApplicationDocumentsDirectory();
          final out = File(p.join(dir.path, 'backups', fileName))
            ..createSync(recursive: true);
          await out.writeAsBytes(bytes);
          await _state.setLastBackupAt(now);
          await _state.clearDirty();
          return (ok: true, message: '已导出到本地：${out.path}');
        case BackupChannelType.aliyunDrive:
        case BackupChannelType.baiduPcs:
          return (ok: false, message: '该通道尚未实现');
        default:
          final password = await _state.loadPassword();
          final client = WebDavClient(
            baseUrl: config.normalizedUrl,
            username: config.username,
            password: password,
          );
          await client.ensureDir(_remoteDir);
          await client.upload('$_remoteDir/$fileName', bytes);
          await _applyRetention(client);
          await _state.setLastBackupAt(now);
          await _state.clearDirty();
          return (ok: true, message: '备份成功：$fileName');
      }
    } catch (e) {
      return (ok: false, message: '备份失败：$e');
    }
  }

  /// 云端保留最近 3 个版本
  Future<void> _applyRetention(WebDavClient client) async {
    final files = await client.listFiles(_remoteDir);
    final backups = files.where((f) => f.startsWith(_backupPrefix)).toList()
      ..sort();
    while (backups.length > _maxVersions) {
      final oldest = backups.removeAt(0);
      await client.delete('$_remoteDir/$oldest');
    }
  }

  /// 列出云端备份（恢复选择用）
  Future<List<String>> listRemoteBackups() async {
    final config = _state.loadConfig();
    if (config == null) return const [];
    final password = await _state.loadPassword();
    final client = WebDavClient(
      baseUrl: config.normalizedUrl,
      username: config.username,
      password: password,
    );
    final files = await client.listFiles(_remoteDir);
    return files.where((f) => f.startsWith(_backupPrefix)).toList()..sort();
  }

  /// 恢复：取最新备份 → （解密）→ 解包 → 覆盖 DB 与图片
  Future<({bool ok, String message})> restoreLatest() async {
    final config = _state.loadConfig();
    if (config == null) {
      return (ok: false, message: '请先配置备份通道');
    }
    try {
      final password = await _state.loadPassword();
      final client = WebDavClient(
        baseUrl: config.normalizedUrl,
        username: config.username,
        password: password,
      );
      final backups = await listRemoteBackups();
      if (backups.isEmpty) {
        return (ok: false, message: '云端没有可用备份');
      }
      final latest = backups.last;
      var bytes = await client.download('$_remoteDir/$latest');

      if (BackupCrypto.isEncrypted(bytes)) {
        bytes = BackupCrypto.decrypt(bytes, password);
      }

      await applyPackage(bytes);
      return (ok: true, message: '恢复成功：$latest');
    } on BackupCryptoException catch (e) {
      return (ok: false, message: e.message);
    } catch (e) {
      return (ok: false, message: '恢复失败：$e');
    }
  }

  /// 解包并覆盖当前数据（DB 文件 + 图片）
  Future<void> applyPackage(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final dir = await getApplicationDocumentsDirectory();

    // 1) 关闭当前数据库
    final db = _dbFactory();
    await db.close();

    // 2) 还原 DB 文件
    final dbFile = File(p.join(dir.path, 'ai_study_growth.sqlite'));
    for (final f in archive.files) {
      if (f.name == 'study_growth.db') {
        await dbFile.writeAsBytes(f.content as List<int>);
      }
    }

    // 3) 还原图片
    final captureDir = Directory(p.join(dir.path, 'captures'))
      ..createSync(recursive: true);
    for (final f in archive.files) {
      if (f.name.startsWith('images/')) {
        final name = p.basename(f.name);
        if (name.isEmpty) continue;
        await File(p.join(captureDir.path, name))
            .writeAsBytes(f.content as List<int>);
      }
    }

    // 4) 重新打开数据库（holder 会重建实例）
    AppDatabaseHolder.reopen();
  }

  String _stamp(DateTime t) =>
      '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}'
      '_${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}${t.second.toString().padLeft(2, '0')}';
}
