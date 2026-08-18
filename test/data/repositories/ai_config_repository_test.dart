import 'package:ai_study_growth/src/data/repositories/ai_config_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeBaseUrl（Prompt G3）', () {
    test('自动补全 https:// 前缀', () {
      expect(
        AiConfigRepository.normalizeBaseUrl('api.example.com/v1'),
        'https://api.example.com/v1',
      );
    });

    test('已有协议不重复添加', () {
      expect(
        AiConfigRepository.normalizeBaseUrl('http://localhost:8080/v1'),
        'http://localhost:8080/v1',
      );
      expect(
        AiConfigRepository.normalizeBaseUrl('https://api.example.com/v1'),
        'https://api.example.com/v1',
      );
    });

    test('规范化尾斜杠', () {
      expect(
        AiConfigRepository.normalizeBaseUrl('api.example.com/v1///'),
        'https://api.example.com/v1',
      );
    });

    test('去首尾空格，空输入返回空', () {
      expect(AiConfigRepository.normalizeBaseUrl('  api.x.com  '),
          'https://api.x.com');
      expect(AiConfigRepository.normalizeBaseUrl(''), '');
    });
  });

  group('classifyDioError（Prompt G2）', () {
    DioException of(DioExceptionType type, {int? status}) => DioException(
          requestOptions: RequestOptions(path: '/models'),
          type: type,
          response: status == null
              ? null
              : Response(
                  requestOptions: RequestOptions(path: '/models'),
                  statusCode: status,
                ),
        );

    test('401 → 认证失败', () {
      expect(
        AiConfigRepository.classifyDioError(
            of(DioExceptionType.badResponse, status: 401)),
        contains('认证失败'),
      );
    });

    test('404 → 地址无效', () {
      expect(
        AiConfigRepository.classifyDioError(
            of(DioExceptionType.badResponse, status: 404)),
        contains('地址无效'),
      );
    });

    test('超时 → 请求超时', () {
      expect(
        AiConfigRepository.classifyDioError(
            of(DioExceptionType.connectionTimeout)),
        contains('超时'),
      );
    });

    test('连接错误 → 地址无效或网络不可达', () {
      expect(
        AiConfigRepository.classifyDioError(
            of(DioExceptionType.connectionError)),
        contains('无法连接'),
      );
    });
  });
}
