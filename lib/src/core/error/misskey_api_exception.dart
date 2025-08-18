/// Misskey API 呼び出し時の共通例外
class MisskeyApiException implements Exception {
  final int? statusCode;
  final String? code; // Misskey固有のエラーコード等があれば格納
  final String message;
  final Object? raw;

  const MisskeyApiException({
    this.statusCode,
    this.code,
    required this.message,
    this.raw,
  });

  @override
  String toString() =>
      'MisskeyApiException(statusCode: '
      '$statusCode, code: $code, message: $message)';
}
