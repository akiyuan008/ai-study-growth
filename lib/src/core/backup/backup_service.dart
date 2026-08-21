import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
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

  Future<void> saveConfig(BackupChannelConfig config,
      {required String password}) async {
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

/// 备份服务（v15 终版）：
/// 坚果云（地址写死+应用密码提示）/ InfiniCLOUD（地址自动拼）/ 自定义 WebDAV / 本地导出
/// 全量备份含 AI 配置（服务商/Base URL/模型/名称）
/// API Key 仅用户设备份密码时加密入包，未设密码则不入包且恢复后引导重输
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
  static const _backupPrefix = 'backup_';

  /// 坚果云预设 WebDAV 地址
  static const String jianguoyunBaseUrl = 'https://dav.jianguoyun.com/dav/';

  /// InfiniCLOUD 自动拼地址
  static String infinicloudBaseUrl(String username) =>
      'https://$username.infini-cloud.com/dav/';

  /// 打包：DB 一致性快照 + 错题图片 + manifest.json → zip 字节
  ///
  /// v15 终版：
  /// - 全量备份含 AI 配置（ai_providers 表保留 name/baseUrl/model/name 字段）
  /// - API Key 本体在 secure storage，不入包
  /// - 用户设置了备份密码时加密整个 zip 包
  /// - 未设密码则不入包且恢复后引导重输 API Key
  Future<Uint8List> buildPackage({required DateTime now}) async {
    final dir = await getApplicationDocumentsDirectory();
    final workDir = Directory(p.join(dir.path, 'backup_tmp'))
      ..createSync(recursive: true);

    // 1) DB 一致性快照（SQLite VACUUM INTO，无需关库）
    final dbCopy = File(p.join(workDir.path, 'study_growth.db'));
    if (dbCopy.existsSync()) dbCopy.deleteSync();
    final db = _dbFactory();
    await db.customStatement("VACUUM INTO '${dbCopy.path}'");

    // 2) 从快照中清空 API Key 引用（保留 AI 配置元数据：name/baseUrl/model）
    //    ai_providers 表中 keyRef 字段置空，但保留其他字段用于恢复后展示
    final tmpDb = AppDatabase.openFile(dbCopy.path);
    // 不删除整表！只清除 keyRef 指针
    await (tmpDb.update(tmpDb.aiProviders))
        .write(const AiProvidersCompanion(keyRef: Value('')));
    await tmpDb.close();

    // 3) manifest（含 AI 配置摘要，不含任何密钥）
    final images = _collectImages(dir.path);
    final aiConfigs = await _collectAiConfigs(db);

    final manifest = {
      'app': '智析录 ai-study-growth',
      'format': 1,
      'createdAt': now.toIso8601String(),
      'dbFile': 'study_growth.db',
      'imageCount': images.length,
      'aiConfigCount': aiConfigs.length,
      'note': '全量备份：题目/图片/复习状态/AI配置。API Key 不在此包内。',
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
      addFile('images/${p.basename(img.path)}', await img.readAsBytes());
    }

    final zipped = ZipEncoder().encode(archive);
    // 清理临时目录
    try {
      workDir.deleteSync(recursive: true);
    } catch (_) {}
    return Uint8List.fromList(zipped ?? const []);
  }

  /// 收集 AI 配置摘要（不含 keyRef）
  Future<List<Map<String, dynamic>>> _collectAiConfigs(AppDatabase db) async {
    final rows = await db.select(db.aiProviders).get();
    return rows
        .map((r) => {
              'name': r.name,
              'baseUrl': r.baseUrl,
              'model': r.model,
            })
        .toList();
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
      final bytes = await buildPackage(now: now);
      final fileName =
          '$_backupPrefix${_stamp(now)}${config.encryptEnabled ? '.zip.enc' : '.zip'}';

      switch (config.type) {
        case BackupChannelType.localExport:
          final dir = await getApplicationDocumentsDirectory();
          final out = File(p.join(dir.path, 'backups', fileName))
            ..createSync(recursive: true);
          await out.writeAsBytes(bytes);
          await _state.setLastBackupAt(now);
          await _state.clearDirty();
          return (ok: true, message: '已导出到本地：${out.path}');

        case BackupChannelType.jianguoyun:
          // 坚果云：地址写死 + 应用密码提示
          final jyPassword = await _state.loadPassword();
          final jyClient = WebDavClient(
            baseUrl: jianguoyunBaseUrl,
            username: config.username,
            password: jyPassword,
          );
          await jyClient.ensureDir(_remoteDir);
          await jyClient.upload('$_remoteDir/$fileName', bytes);
          await _applyRetention(jyClient);
          await _state.setLastBackupAt(now);
          await _state.clearDirty();
          return (ok: true, message: '备份成功（坚果云）：$fileName');

        case BackupChannelType.infinicloud:
          // InfiniCLOUD：地址自动拼
          final infPassword = await _state.loadPassword();
          final infUrl = infinicloudBaseUrl(config.username);
          final infClient = WebDavClient(
            baseUrl: infUrl,
            username: config.username,
            password: infPassword,
          );
          await infClient.ensureDir(_remoteDir);
          await infClient.upload('$_remoteDir/$fileName', bytes);
          await _applyRetention(infClient);
          await _state.setLastBackupAt(now);
          await _state.clearDirty();
          return (ok: true, message: '备份成功（InfiniCLOUD）：$fileName');

        case BackupChannelType.aliyunDrive:
        case BackupChannelType.baiduPcs:
          return (ok: false, message: '该通道尚未实现');

        default:
          // 自定义 WebDAV
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
    final baseUrl = switch (config.type) {
      BackupChannelType.jianguoyun => jianguoyunBaseUrl,
      BackupChannelType.infinicloud => infinicloudBaseUrl(config.username),
      _ => config.normalizedUrl,
    };
    final client = WebDavClient(
      baseUrl: baseUrl,
      username: config.username,
      password: password,
    );
    final files = await client.listFiles(_remoteDir);
    return files.where((f) => f.startsWith(_backupPrefix)).toList()..sort();
  }

  /// 恢复：取最新备份 → （解密）→ 解包 → 覆盖 DB 与图片
  /// 恢复后引导用户重新输入 API Key（因为 Key 不在备份包中）
  Future<({bool ok, String message, bool needsReinputApiKey})>
      restoreLatest() async {
    final config = _state.loadConfig();
    if (config == null) {
      return (ok: false, message: '请先配置备份通道', needsReinputApiKey: false);
    }
    try {
      final password = await _state.loadPassword();
      final baseUrl = switch (config.type) {
        BackupChannelType.jianguoyun => jianguoyunBaseUrl,
        BackupChannelType.infinicloud => infinicloudBaseUrl(config.username),
        _ => config.normalizedUrl,
      };
      final client = WebDavClient(
        baseUrl: baseUrl,
        username: config.username,
        password: password,
      );
      final backups = await listRemoteBackups();
      if (backups.isEmpty) {
        return (ok: false, message: '云端没有可用备份', needsReinputApiKey: false);
      }
      final latest = backups.last;
      var bytes = await client.download('$_remoteDir/$latest');

      if (BackupCrypto.isEncrypted(bytes)) {
        bytes = BackupCrypto.decrypt(bytes, password);
      }

      await applyPackage(bytes);

      // 检查是否需要重新输入 API Key
      final needsReinputApiKey = !config.encryptEnabled;

      return (
        ok: true,
        message: needsReinputApiKey
            ? '恢复成功！请在「设置 → AI 服务商」重新输入 API Key'
            : '恢复成功：$latest',
        needsReinputApiKey: needsReinputApiKey,
      );
    } on BackupCryptoException catch (e) {
      return (ok: false, message: e.message, needsReinputApiKey: false);
    } catch (e) {
      return (ok: false, message: '恢复失败：$e', needsReinputApiKey: false);
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
