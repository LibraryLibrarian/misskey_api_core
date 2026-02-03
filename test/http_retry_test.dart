import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:test/test.dart';
import 'package:misskey_api_core/misskey_api_core.dart' as core;

class _FlakyAdapter implements dio.HttpClientAdapter {
  /// 先頭の数回は503を返し、その後200を返す不安定アダプタ
  /// リトライの有無/回数を検証するために試行回数を記録
  int attempts = 0;
  final int failCount;
  _FlakyAdapter(this.failCount);

  @override
  void close({bool force = false}) {}

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    attempts++;
    if (attempts <= failCount) {
      // 503 を返して再試行させる
      return dio.ResponseBody.fromString('service unavailable', 503);
    }
    return dio.ResponseBody.fromBytes(
      utf8.encode('{"ok":true}'),
      200,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  /// idempotent=true の場合、503など一時エラーで所定回数だけリトライして成功することを検証
  test('idempotent=true の場合、503など一時エラーで所定回数だけリトライして成功することを検証', () async {
    final adapter = _FlakyAdapter(2);
    final client = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(
        baseUrl: Uri.parse('https://example.com'),
        enableLog: false,
        maxRetries: 3,
        retryInitialDelay: const Duration(milliseconds: 1),
        retryMaxDelay: const Duration(milliseconds: 2),
      ),
      httpClientAdapter: adapter,
    );

    final res = await client.send<Map<String, dynamic>>(
      '/dummy',
      method: 'POST',
      body: const {},
      options: const core.RequestOptions(idempotent: true),
    );

    expect(adapter.attempts, 3);
    expect(res['ok'], true);
  });

  /// idempotent=false の場合、リトライせずに例外を投げることを検証
  test('idempotent=false の場合、リトライせずに例外を投げることを検証', () async {
    final adapter = _FlakyAdapter(1);
    final client = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(
        baseUrl: Uri.parse('https://example.com'),
        enableLog: false,
        maxRetries: 3,
        retryInitialDelay: const Duration(milliseconds: 1),
        retryMaxDelay: const Duration(milliseconds: 2),
      ),
      httpClientAdapter: adapter,
    );

    await expectLater(
      () async => client.send<Map<String, dynamic>>(
        '/dummy',
        method: 'POST',
        body: const {},
        options: const core.RequestOptions(idempotent: false),
      ),
      throwsA(isA<core.MisskeyApiException>().having((e) => e.statusCode, 'status', 503)),
    );
    // 再試行しないこと（1回のみ）
    expect(adapter.attempts, 1);
  });
}
