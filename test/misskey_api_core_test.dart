import 'package:flutter_test/flutter_test.dart';

import 'package:misskey_api_core/misskey_api_core.dart';

void main() {
  test('exports exist', () {
    final config = MisskeyApiConfig(baseUrl: Uri.parse('https://example.com'));
    final client = MisskeyHttpClient(config: config);
    expect(client, isNotNull);
  });
}
