import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 统一 WebDAV 适配器（Part 4.2）：坚果云 / InfiniCLOUD / 自定义 NAS 共用。
class WebDavClient {
  WebDavClient({
    required String baseUrl,
    required String username,
    required String password,
    Dio? dio,
  })  : _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _dio = dio ?? Dio() {
    final token = base64Encode(utf8.encode('$username:$password'));
    _dio.options.headers['Authorization'] = 'Basic $token';
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
  }

  final String _baseUrl;
  final Dio _dio;

  /// 测试连接：PROPFIND 根目录
  Future<({bool ok, String message})> testConnection() async {
    try {
      final resp = await _dio.request<String>(
        _baseUrl,
        options: Options(
          method: 'PROPFIND',
          headers: {'Depth': '0'},
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final code = resp.statusCode ?? 0;
      if (code == 207 || code == 200 || code == 301) {
        return (ok: true, message: '连接成功');
      }
      if (code == 401 || code == 403) {
        return (ok: false, message: '认证失败（$code）：请检查账号与应用密码');
      }
      if (code == 404) {
        return (ok: false, message: '地址无效（404）：请检查服务器地址');
      }
      return (ok: false, message: '服务异常（$code）');
    } on DioException catch (e) {
      return (ok: false, message: _classifyError(e));
    } catch (_) {
      return (ok: false, message: '连接失败：网络不可达');
    }
  }

  /// 确保目录存在（逐级 MKCOL）
  Future<void> ensureDir(String relPath) async {
    final segments = relPath.split('/').where((s) => s.isNotEmpty);
    var current = '';
    for (final seg in segments) {
      current = '$current$seg/';
      try {
        await _dio.request<void>(
          '$_baseUrl$current',
          options: Options(
            method: 'MKCOL',
            validateStatus: (s) => s != null && s < 500,
          ),
        );
      } catch (_) {
        // 已存在（405）或父目录问题都继续，PUT 时会最终校验
      }
    }
  }

  /// 上传文件
  Future<void> upload(String relPath, Uint8List bytes) async {
    await _dio.put<dynamic>(
      '$_baseUrl$relPath',
      data: Stream.fromIterable(bytes.map((e) => [e])),
      options: Options(headers: {
        'Content-Length': bytes.length,
        'Content-Type': 'application/octet-stream',
      }),
    );
  }

  /// 下载文件
  Future<Uint8List> download(String relPath) async {
    final resp = await _dio.get<List<int>>(
      '$_baseUrl$relPath',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(resp.data ?? const []);
  }

  /// 删除文件
  Future<void> delete(String relPath) async {
    await _dio.request<void>(
      '$_baseUrl$relPath',
      options: Options(
        method: 'DELETE',
        validateStatus: (s) => s != null && s < 500,
      ),
    );
  }

  /// 列出目录下的文件名（解析 multistatus XML 的 href）
  Future<List<String>> listFiles(String relPath) async {
    final resp = await _dio.request<String>(
      '$_baseUrl$relPath',
      options: Options(
        method: 'PROPFIND',
        headers: {'Depth': '1'},
        responseType: ResponseType.plain,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    final body = resp.data ?? '';
    final names = <String>[];
    final hrefs = RegExp(r'<[^>]*href[^>]*>([^<]+)</[^>]*href[^>]*>',
            caseSensitive: false)
        .allMatches(body);
    for (final m in hrefs) {
      final href = Uri.decodeComponent(m.group(1) ?? '').trim();
      if (href.isEmpty || href.endsWith('/')) continue;
      names.add(href.split('/').where((s) => s.isNotEmpty).last);
    }
    return names.toSet().toList();
  }

  String _classifyError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '请求超时：检查网络与地址';
      case DioExceptionType.connectionError:
        return '无法连接：地址无效或网络不可达';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          return '认证失败（$code）：请检查账号与应用密码';
        }
        if (code == 404) {
          return '地址无效（404）：请检查服务器地址';
        }
        return '服务异常（$code）';
      default:
        return '连接失败：${e.message ?? '未知原因'}';
    }
  }
}
