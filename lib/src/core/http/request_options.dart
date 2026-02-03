/// リクエスト単位のオプション。
class RequestOptions {
  /// リクエスト単位のオプション
  ///
  /// - [authRequired]: 認証必須か（デフォルト: true）
  /// - [idempotent]: 冪等なリクエストか（デフォルト: false）
  /// - [contentType]: リクエストのContent-Type（未指定時はDioが推論）
  /// - [headers]: リクエスト固有の追加ヘッダ
  /// - [extra]: Dioの`Options.extra`へ渡す追加情報
  const RequestOptions({
    this.authRequired = true,
    this.idempotent = false,
    this.contentType,
    this.headers = const {},
    this.extra = const {},
  });

  /// 認証必須か。true の場合 POST の JSON body に `i` を自動注入する
  final bool authRequired;

  /// 冪等リクエストか。true の場合のみ自動リトライ対象
  final bool idempotent;

  /// このリクエストのContent-Typeを明示的に指定する。未指定時はDioが推論する
  final String? contentType;

  /// このリクエスト固有の追加ヘッダ
  final Map<String, String> headers;

  /// Dioの`Options.extra`に引き継ぐ追加情報
  final Map<String, dynamic> extra;
}
