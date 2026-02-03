/// Misskey API 呼び出し時の共通例外
class MisskeyApiException implements Exception {
  /// 共通例外コンテナ
  const MisskeyApiException({this.statusCode, this.code, required this.message, this.raw, this.retryAfter});

  /// HTTP ステータスコード
  final int? statusCode;

  /// Misskey固有のエラーコード等があれば格納
  final String? code;

  /// エラーメッセージ（人間可読）
  final String message;

  /// 元例外やエラーオブジェクト
  final Object? raw;

  /// 429 Too Many Requests 時に応じるまでの推奨待機時間
  final Duration? retryAfter;

  @override
  String toString() =>
      'MisskeyApiException(statusCode: $statusCode, code: $code, message: $message, retryAfter: $retryAfter)';
}
