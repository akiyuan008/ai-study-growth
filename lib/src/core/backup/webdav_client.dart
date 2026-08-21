import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// WebDAV 客户端（v15 终版：修复上传效率 —— 改用整块流而非逐字节流）
class WebDavClient {
  WebDavClient({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  final String baseUrl;
  final String username;
  final String password;

  /// 基础认证头
  Map<String, String> get _auth => {
        'Authorization': 'Basic ${base64Encode(
          utf8.encode('$username:$password'),
        )}',
      };

  /// 确保远程目录存在（MKCOL 递归创建）
  Future<void> ensureDir(String dirPath) async {
    final parts = dirPath.split('/').where((s) => s.isNotEmpty).toList();
    var current = '';
    for (final part in parts) {
      current += '/$part';
      final url = '$baseUrl${Uri.encodeComponent(current)}';
      try {
        final resp = await http.head(Uri.parse(url), headers: _auth);
        if (resp.statusCode == 200 || resp.statusCode == 207) continue;
      } catch (_) {}
      // 目录不存在，尝试创建
      try {
        final mkcolResp = await http.Client().send(
          http.Request('MKCOL', Uri.parse(url))..headers.addAll(_auth),
        );
        if (mkcolResp.statusCode != 201 && mkcolResp.statusCode != 405) {
          throw Exception('MKCOL 失败: ${mkcolResp.statusCode}');
        }
      } catch (e) {
        throw Exception('创建目录 $current 失败: $e');
      }
    }
  }

  /// 上传文件（v15 终版：使用整块流而非逐字节流）
  ///
  /// 旧版问题：`Stream.fromIterable(bytes.map((e) => [e]))` 将整个文件拆成单字节数组，
  /// 一个 10MB 文件产生 1000 万个片段，内存和性能灾难。
  ///
  /// 修复后：`Stream.fromIterable([bytes])` 整块传输。
  Future<void> upload(String remotePath, List<int> bytes) async {
    final url = '$baseUrl${Uri.encodeComponent(remotePath)}';
    final resp = await http.put(
      Uri.parse(url),
      headers: {
        ..._auth,
        'Content-Type': 'application/octet-stream',
        'Content-Length': bytes.length.toString(),
      },
      body: Stream.fromIterable([Uint8List.fromList(bytes)]),
    );
    if (resp.statusCode != 201 && resp.statusCode != 204) {
      throw Exception('上传失败 ($remotePath): ${resp.statusCode} ${resp.body}');
    }
  }

  /// 下载文件
  Future<Uint8List> download(String remotePath) async {
    final url = '$baseUrl${Uri.encodeComponent(remotePath)}';
    final resp = await http.get(Uri.parse(url), headers: _auth);
    if (resp.statusCode != 200 && resp.statusCode != 206) {
      throw Exception('下载失败 ($remotePath): ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }

  /// 删除文件
  Future<void> delete(String remotePath) async {
    final url = '$baseUrl${Uri.encodeComponent(remotePath)}';
    final resp = await http.delete(Uri.parse(url), headers: _auth);
    if (resp.statusCode != 204 &&
        resp.statusCode != 200 &&
        resp.statusCode != 404) {
      throw Exception('删除失败 ($remotePath): ${resp.statusCode}');
    }
  }

  /// 列出目录内容（PROPFIND depth=1）
  Future<List<String>> listFiles(String dirPath) async {
    final url = '$baseUrl${Uri.encodeComponent(dirPath)}/';
    final client = http.Client();
    final req = http.Request('PROPFIND', Uri.parse(url));
    req.headers.addAll({
      ..._auth,
      'Depth': '1',
      'Content-Type': 'application/xml',
    });
    req.body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop><d:displayname/></d:prop>
</d:propfind>''';
    final streamedResp = await client.send(req);
    final resp = await http.Response.fromStream(streamedResp);
    client.close();
    if (resp.statusCode != 207) {
      throw Exception('列出目录失败 ($dirPath): ${resp.statusCode}');
    }
    // 解析多状态响应中的 href
    final names = <String>[];
    final lines = resp.body.split('\n');
    for (final line in lines) {
      final m = RegExp(r'<d:href>([^<]+)</d:href>').firstMatch(line);
      if (m == null) continue;
      final raw = m.group(1)!;
      final decoded = Uri.decodeComponent(raw);
      final name =
          decoded.split('/').lastWhere((s) => s.isNotEmpty, orElse: () => '');
      if (name.isEmpty || name.startsWith('.')) continue;
      names.add(name);
    }
    return names;
  }

  /// 测试连接（PUT 一个临时文件再删除）
  Future<({bool ok, String message})> testConnection() async {
    try {
      final testFile =
          '.connection_test_${DateTime.now().millisecondsSinceEpoch}';
      await ensureDir(_remoteDir);
      await upload('$_remoteDir/$testFile', [0x00]);
      await delete('$_remoteDir/$testFile');
      return (ok: true, message: '连接成功');
    } catch (e) {
      return (ok: false, message: '连接失败：$e');
    }
  }

  static const String _remoteDir = 'StudyGrowthBackup';
}
