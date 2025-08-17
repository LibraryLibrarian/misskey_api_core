import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_api_core/misskey_api_core.dart' as core;

class _ErrorAdapter implements dio.HttpClientAdapter {
  /// 指定ステータス/ボディで常にエラーレスポンスを返すテスト用アダプタ
  final int status;
  final Map<String, dynamic> body;

  _ErrorAdapter(this.status, this.body);

  @override
  void close({bool force = false}) {}

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    final bytes = utf8.encode(jsonEncode(body));
    return dio.ResponseBody.fromBytes(
      bytes,
      status,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  /// `{ error: { code, message } }` 形式のMisskeyエラーが
  /// `MisskeyApiException(code, message, statusCode)` に正規化されることを検証
  test('maps Misskey error format with nested error object', () async {
    final client = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com')),
      httpClientAdapter: _ErrorAdapter(400, {
        'error': {'code': 'SOME_ERROR', 'message': 'oops'},
      }),
    );

    expect(
      () async => client.send('/dummy', body: const {}),
      throwsA(
        isA<core.MisskeyApiException>()
            .having((e) => e.code, 'code', 'SOME_ERROR')
            .having((e) => e.statusCode, 'status', 400)
            .having((e) => e.message, 'message', 'oops'),
      ),
    );
  });

  /// `{ code, message }` のフラットなエラーフォーマットも
  /// 同様に正規化されることを検証する
  test('maps flat error format too', () async {
    final client = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com')),
      httpClientAdapter: _ErrorAdapter(403, {
        'code': 'FORBIDDEN',
        'message': 'nope',
      }),
    );

    expect(
      () async => client.send('/dummy', body: const {}),
      throwsA(
        isA<core.MisskeyApiException>()
            .having((e) => e.code, 'code', 'FORBIDDEN')
            .having((e) => e.statusCode, 'status', 403)
            .having((e) => e.message, 'message', 'nope'),
      ),
    );
  });
}
