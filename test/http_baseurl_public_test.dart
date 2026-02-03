import 'package:misskey_api_core/misskey_api_core.dart' as core;
import 'package:test/test.dart';

void main() {
  /// MisskeyHttpClientの `baseUrl` プロパティが、
  /// `/api` 正規化前の元のベースURL（MisskeyApiConfigで指定したもの）を
  /// 正しく公開していることを検証するテスト
  ///
  /// - `baseUrl` には `/api` が付与されていない元のURLがそのまま格納されていること
  test('MisskeyHttpClientのbaseUrlは元のURL（/api付与前）を公開する', () {
    final base = Uri.parse('https://host.example/app');
    final http =
        core.MisskeyHttpClient(config: core.MisskeyApiConfig(baseUrl: base));
    expect(http.baseUrl, base);
  });
}
