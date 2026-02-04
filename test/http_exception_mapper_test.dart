import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:misskey_api_core/misskey_api_core.dart' as core;
import 'package:test/test.dart';

class _ErrorAdapter implements dio.HttpClientAdapter {
  _ErrorAdapter(this.statusCode);
  final int statusCode;

  @override
  void close({bool force = false}) {}

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    return dio.ResponseBody.fromBytes(
      utf8.encode(
        jsonEncode(<String, dynamic>{
          'error': {'code': 'SOME', 'message': 'oops'},
        }),
      ),
      statusCode,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class MyUnifiedException implements Exception {
  const MyUnifiedException();
}

void main() {
  /// `exceptionMapper` フックが MisskeyApiException をカスタム例外に変換できることを検証するテスト
  ///
  /// - MisskeyHttpClient の `exceptionMapper` に、MisskeyApiException を受け取った際に
  ///   独自の MyUnifiedException に変換する関数を指定する
  /// - サーバーが 500 エラー（Misskey 形式のエラー）を返す状況を模擬し、
  ///   send() 実行時に MyUnifiedException が投げられることを確認する
  test('exceptionMapperでMisskeyApiExceptionをカスタム例外に変換できる', () {
    final http = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com')),
      httpClientAdapter: _ErrorAdapter(500),
      exceptionMapper: (Object error) {
        if (error is core.MisskeyApiException) {
          return const MyUnifiedException();
        }
        return error is Exception
            ? error
            : core.MisskeyApiException(
                message: 'Unexpected error',
                raw: error,
              );
      },
    );

    expect(
      () => http.send<dynamic>('/x', body: const <String, dynamic>{}),
      throwsA(isA<MyUnifiedException>()),
    );
  });
}
