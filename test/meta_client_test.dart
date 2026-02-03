import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:misskey_api_core/misskey_api_core.dart' as core;
import 'package:test/test.dart';

class _MetaAdapter implements dio.HttpClientAdapter {
  _MetaAdapter(this.response);
  /// `/api/meta`に対して固定のレスポンスを返すテスト用アダプタ
  /// 呼び出し回数をカウントし、キャッシュが効いているかを検証。
  final Map<String, dynamic> response;
  int calls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    calls++;
    return dio.ResponseBody.fromBytes(
      utf8.encode(jsonEncode(response)),
      200,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  /// `MetaClient.getMeta()` が結果をキャッシュし、
  /// `supports()` で機能有無が正しく判定できることを検証する
  test('MetaClient がキャッシュを効かせて機能有無を正しく判定できることを検証', () async {
    final adapter = _MetaAdapter({
      'version': '2024.12.0',
      'name': 'misskey.example',
      'features': {'groups': true},
    });
    final http = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com')),
      httpClientAdapter: adapter,
    );
    final metaClient = core.MetaClient(http);

    final meta1 = await metaClient.getMeta();
    final meta2 = await metaClient.getMeta();
    expect(identical(meta1, meta2), true); // キャッシュ
    expect(adapter.calls, 1);

    expect(metaClient.supports('features.groups'), true);
    expect(metaClient.supports('features.unknown'), false);
  });
}
