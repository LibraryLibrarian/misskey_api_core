import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:test/test.dart';
import 'package:misskey_api_core/misskey_api_core.dart' as core;

/// テスト用の可変レスポンスを返すHttpClientAdapter
///
/// このクラスはDioの[HttpClientAdapter]を実装し、
/// [response]プロパティで指定されたMapをJSONとして返すダミーのHTTPクライアントアダプタ
/// fetchが呼ばれるたびに[calls]がインクリメントされ、
/// サーバーレスポンスを動的に書き換えてテストできるようにする
class _MutableMetaAdapter implements dio.HttpClientAdapter {
  /// 現在返すレスポンス(JSONとしてシリアライズされる)
  Map<String, dynamic> response;

  /// fetchが呼ばれた回数
  int calls = 0;

  /// [response]で初期化
  _MutableMetaAdapter(this.response);

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
  /// MetaClientのキャッシュ挙動とrefreshオプションの動作を検証するテスト
  ///
  /// - 最初のgetMeta()呼び出しでサーバーからメタ情報を取得し、キャッシュされることを確認する
  /// - 2回目のgetMeta()呼び出しではキャッシュが利用され、サーバーへのリクエストが発生しないことを確認する
  /// - サーバーレスポンスを書き換えた後、getMeta(refresh: true)でキャッシュを無視して再取得し、
  ///   新しい値が取得されることとリクエスト回数が増えることを確認する
  test('MetaClient getMeta(refresh: true) でキャッシュを無視して再取得できることを検証', () async {
    final adapter = _MutableMetaAdapter({'version': 'v1', 'name': 'example'});
    final http = core.MisskeyHttpClient(
      config: core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com')),
      httpClientAdapter: adapter,
    );
    final metaClient = core.MetaClient(http);

    final meta1 = await metaClient.getMeta();
    expect(meta1.version, 'v1');
    expect(adapter.calls, 1);

    // 通常呼び出しはキャッシュ
    final meta2 = await metaClient.getMeta();
    expect(identical(meta1, meta2), true);
    expect(adapter.calls, 1);

    // サーバーレスポンスが変わった想定
    adapter.response = {'version': 'v2', 'name': 'example'};

    // refresh指定で再取得
    final meta3 = await metaClient.getMeta(refresh: true);
    expect(meta3.version, 'v2');
    expect(adapter.calls, 2);
  });
}
