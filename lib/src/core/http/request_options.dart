/// リクエスト単位のオプション。
class RequestOptions {
  /// 認証必須か。true の場合 POST の JSON body に `i` を自動注入する
  final bool authRequired;

  /// 冪等リクエストか。true の場合のみ自動リトライ対象
  final bool idempotent;

  const RequestOptions({this.authRequired = true, this.idempotent = false});
}
