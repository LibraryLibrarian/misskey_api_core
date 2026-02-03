import 'package:test/test.dart';
import 'package:misskey_api_core/misskey_api_core.dart';

void main() {
  /// 公開APIのスモークテスト
  /// 必要最小のエクスポート（Config/HttpClient）が利用可能であることを確認
  test('MisskeyApiCore が必要最小のエクスポートを提供することを検証', () {
    final config = MisskeyApiConfig(baseUrl: Uri.parse('https://example.com'));
    final client = MisskeyHttpClient(config: config);
    expect(client, isNotNull);
  });
}
