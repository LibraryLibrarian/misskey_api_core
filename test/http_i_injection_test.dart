import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:test/test.dart';
import 'package:misskey_api_core/misskey_api_core.dart' as core;

class _CapturingAdapter implements dio.HttpClientAdapter {
  /// テスト用のDioアダプタ
  /// 送信されたRequestOptionsを捕捉し、bodyに`i`が注入されたかを検証するために使用
  late dio.RequestOptions lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    lastOptions = options;
    // 回答は常に200/JSONで返す
    final bytes = utf8.encode('{"ok":true}');
    return dio.ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  /// authRequiredがtrueのPOSTでは、JSON bodyにトークン`i`が自動注入されることを検証
  test('authRequired=true のPOSTでは、JSON bodyにトークン`i`が自動注入されることを検証', () async {
    final adapter = _CapturingAdapter();
    final client = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com')),
      tokenProvider: () async => 'TOKEN',
      httpClientAdapter: adapter,
    );

    await client.send<Map<String, dynamic>>(
      '/dummy',
      method: 'POST',
      body: {'a': 1},
      options: const core.RequestOptions(authRequired: true),
    );

    expect(adapter.lastOptions.data is Map<String, dynamic>, true);
    final map = adapter.lastOptions.data as Map<String, dynamic>;
    expect(map['i'], 'TOKEN');
    expect(map['a'], 1);
  });

  /// authRequiredがfalseのPOSTでは、`i`が注入されないことを検証
  test('authRequired=false のPOSTでは、`i`が注入されないことを検証', () async {
    final adapter = _CapturingAdapter();
    final client = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com')),
      tokenProvider: () async => 'TOKEN',
      httpClientAdapter: adapter,
    );

    await client.send<Map<String, dynamic>>(
      '/dummy',
      method: 'POST',
      body: {'a': 1},
      options: const core.RequestOptions(authRequired: false),
    );

    expect(adapter.lastOptions.data is Map<String, dynamic>, true);
    final map = adapter.lastOptions.data as Map<String, dynamic>;
    expect(map.containsKey('i'), false);
    expect(map['a'], 1);
  });
}
