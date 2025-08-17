import 'package:meta/meta.dart';

/// Misskey API 呼び出しに関するクライアント設定
@immutable
class MisskeyApiConfig {
  /// 例: https://example.com
  final Uri baseUrl;

  /// 接続/送受信を包括するタイムアウト
  final Duration timeout;

  /// User-Agent を上書きしたい場合に指定
  final String? userAgent;

  /// 既定ヘッダ。UAやAcceptはクライアント側で付与されるため、通常は追加分のみを指定
  final Map<String, String> defaultHeaders;

  /// リトライ最大試行回数（1 = リトライ無し）
  final int maxRetries;

  /// リトライ初期待機時間
  final Duration retryInitialDelay;

  /// リトライ最大待機時間
  final Duration retryMaxDelay;

  /// ログ出力を有効にするか（機密値は可能な範囲でマスク）
  final bool enableLog;

  const MisskeyApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
    this.userAgent,
    this.defaultHeaders = const {},
    this.maxRetries = 3,
    this.retryInitialDelay = const Duration(milliseconds: 500),
    this.retryMaxDelay = const Duration(seconds: 5),
    this.enableLog = false,
  });
}
