import '../core/http/misskey_http_client.dart';
import '../core/http/request_options.dart';
import '../models/meta.dart';

/// `/api/meta` を取得するクライアント
class MetaClient {
  MetaClient(this.http);
  final MisskeyHttpClient http;
  Meta? _cached;

  /// Misskeyサーバの `/api/meta` エンドポイントからメタ情報を取得する
  ///
  /// [refresh] を `true` にするとキャッシュを無視して常に最新の情報を取得する
  /// デフォルトでは、一度取得したメタ情報をキャッシュし、2回目以降はキャッシュを返す
  Future<Meta> getMeta({bool refresh = false}) async {
    if (!refresh && _cached != null) return _cached!;
    final res = await http.send<Map<String, dynamic>>(
      '/meta',
      body: const <String, dynamic>{},
      options: const RequestOptions(authRequired: false, idempotent: true),
    );
    _cached = Meta.fromJson(res);
    return _cached!;
  }

  /// 簡易なサーバーの能力検出（キー存在で判定）
  bool supports(String keyPath) {
    final meta = _cached;
    if (meta == null) return false;
    final parts = keyPath.split('.');
    dynamic cursor = meta.raw;
    for (final p in parts) {
      if (cursor is Map && cursor.containsKey(p)) {
        cursor = cursor[p];
      } else {
        return false;
      }
    }
    return true;
  }
}
