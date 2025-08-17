import '../core/http/request_options.dart';
import '../core/http/misskey_http_client.dart';
import '../models/meta.dart';

/// `/api/meta` を取得するクライアント
class MetaClient {
  final MisskeyHttpClient http;
  Meta? _cached;

  MetaClient(this.http);

  Future<Meta> getMeta() async {
    if (_cached != null) return _cached!;
    final res = await http.send<Map<String, dynamic>>(
      '/meta',
      method: 'POST',
      body: const {},
      options: const RequestOptions(authRequired: false, idempotent: true),
    );
    _cached = Meta.fromJson(res);
    return _cached!;
  }

  /// 簡易な能力検出（キー存在で判定）
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
