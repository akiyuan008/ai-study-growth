import 'dart:async';

import 'package:dio/dio.dart';

/// AI 调用统一治理（Part 1.2）：
/// - 30s 超时
/// - 错误四档：视觉不支持 / 鉴权失败 / 解析失败 / 超时网络
/// - 所有 AI 业务调用必经，零无限转圈
enum AiErrorTier {
  visionUnsupported('当前模型不支持图片理解'),
  authFailed('鉴权失败：请检查 API Key 与账户额度'),
  parseFailed('AI 返回内容无法解析'),
  timeoutNetwork('超时或网络不可达');

  const AiErrorTier(this.userMessage);

  final String userMessage;
}

class AiCallException implements Exception {
  const AiCallException(this.tier, {this.detail});

  final AiErrorTier tier;
  final String? detail;

  String get userMessage => detail == null || detail!.isEmpty
      ? tier.userMessage
      : '${tier.userMessage}（$detail）';

  @override
  String toString() => userMessage;
}

abstract final class AiCall {
  static const Duration timeout = Duration(seconds: 30);

  /// 统一包裹：超时 + 错误分级
  static Future<T> run<T>(Future<T> Function() fn) async {
    try {
      return await fn().timeout(timeout);
    } on AiCallException {
      rethrow;
    } on DioException catch (e) {
      throw classify(e);
    } on TimeoutException {
      throw const AiCallException(AiErrorTier.timeoutNetwork, detail: '30 秒超时');
    } catch (e) {
      throw AiCallException(AiErrorTier.timeoutNetwork, detail: '$e');
    }
  }

  /// DioException → 四档
  static AiCallException classify(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return const AiCallException(AiErrorTier.authFailed);
    }
    if (code == 400 || code == 404 || code == 415) {
      final body = e.response?.data?.toString() ?? '';
      final lower = body.toLowerCase();
      if (lower.contains('image') ||
          lower.contains('vision') ||
          lower.contains('multimodal') ||
          lower.contains('picture')) {
        return const AiCallException(AiErrorTier.visionUnsupported);
      }
    }
    if (code == 400) {
      return AiCallException(AiErrorTier.parseFailed, detail: '请求被拒绝(400)');
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AiCallException(AiErrorTier.timeoutNetwork,
            detail: '请求超时');
      case DioExceptionType.connectionError:
        return const AiCallException(AiErrorTier.timeoutNetwork,
            detail: '无法连接服务器');
      default:
        return AiCallException(AiErrorTier.timeoutNetwork,
            detail: e.message ?? '未知网络错误');
    }
  }
}
