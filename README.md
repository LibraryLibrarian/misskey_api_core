## Misskey API Core Library

English | [日本語](#日本語)

### Overview

Misskey API Core is a Dart/Flutter package that provides the core building blocks to interact with Misskey servers. It focuses on a robust HTTP foundation, unified error handling, token injection, and minimal common models (e.g., Meta) so that domain-specific features (Notes/Users/Drive) can be implemented in separate layers.

### Key Features

- HTTP foundation: base URL handling (/api), timeouts, idempotent retries (429/5xx/network), request/response logging (debug-only)
- Base URL exposure: access original base URL via `client.baseUrl` for derived services
- Auth token injection: automatically injects `i` into POST JSON bodies when `authRequired` is true
- Flexible token providers: support both sync and async token sources via `FutureOr<String?>`
- Unified error: normalize Misskey error response to `MisskeyApiException(statusCode/code/message)`
- Customizable error handling: map exceptions via `exceptionMapper` for unified error policies
- Flexible logging: use `loggerFn` for function-style logging or existing `Logger` interface
- Meta capability: `/api/meta` client with a tiny cache and `supports()` helper
- Meta refresh: force-refresh cached meta data with `getMeta(refresh: true)`
- JSON serialization: `json_serializable`-ready common model(s)

### Install

Add to `pubspec.yaml`:

```yaml
dependencies:
  misskey_api_core: ^0.0.2-beta
```

Then:

```bash
flutter pub get
```

### Quick Start

```dart
import 'package:misskey_api_core/misskey_api_core.dart';

void main() async {
  final client = MisskeyHttpClient(
    config: MisskeyApiConfig(
      baseUrl: Uri.parse('https://misskey.example'), // '/api' is appended automatically
      timeout: const Duration(seconds: 10),
      enableLog: true, // logs only in debug mode
    ),
    tokenProvider: () async => 'YOUR_TOKEN', // or sync: () => 'TOKEN'
  );

  // Fetch meta (no auth)
  final meta = await MetaClient(client).getMeta();
  
  // Force refresh meta data
  final freshMeta = await MetaClient(client).getMeta(refresh: true);

  // Example POST (token `i` will be injected automatically)
  final res = await client.send<List<dynamic>>(
    '/notes/timeline',
    body: {'limit': 10},
    options: const RequestOptions(idempotent: true),
  );
  
  // Access base URL for derived services (e.g., streaming)
  final origin = client.baseUrl;
}
```

See `/example` for a working app including sign-in (with `misskey_auth`), posting a note, timelines, following/followers.

### License

This project is published by 司書 (LibraryLibrarian) under the 3-Clause BSD License. For details, please see the [LICENSE](LICENSE) file.

---

## 日本語

### 概要

Misskey API Core は、Misskeyサーバーと連携するためのDart/Flutter用“基盤”ライブラリです。HTTP基盤、共通例外、トークン自動付与、最低限の共通モデル（例: Meta）にフォーカスし、ノート/ユーザー/Driveなどドメイン固有機能は別レイヤーで実装できるように設計しています。

### 機能

- HTTP基盤: ベースURL（/api付与）・タイムアウト・冪等時の自動リトライ（429/5xx/ネットワーク）・デバッグ時のみログ
- ベースURL公開: `client.baseUrl` で元URLにアクセス（派生サービス用）
- 認証: POSTのJSONボディに `i` を自動注入（`authRequired`で制御）
- 柔軟なトークン供給: 同期・非同期両方に対応（`FutureOr<String?>`）
- 共通例外: Misskeyのエラーを `MisskeyApiException(statusCode/code/message)` に正規化
- カスタマイズ可能な例外処理: `exceptionMapper` で例外を一元変換
- 柔軟なログ出力: 関数ベースロガー（`loggerFn`）または既存Logger IF
- メタ/能力検出: `/api/meta` の取得と簡易キャッシュ、`supports()` ヘルパー
- メタ更新: `getMeta(refresh: true)` でキャッシュを強制更新
- JSONシリアライズ: `json_serializable`対応の共通モデル

### インストール

`pubspec.yaml` に追加:

```yaml
dependencies:
  misskey_api_core: ^0.0.2-beta
```

実行:

```bash
flutter pub get
```

### 使い方

```dart
import 'package:misskey_api_core/misskey_api_core.dart';

final client = MisskeyHttpClient(
  config: MisskeyApiConfig(
    baseUrl: Uri.parse('https://misskey.example'), // '/api' は自動付与
    timeout: const Duration(seconds: 10),
    enableLog: true, // デバッグ時のみ
  ),
  tokenProvider: () async => 'YOUR_TOKEN', // または同期: () => 'TOKEN'
);

// 認証不要
final meta = await MetaClient(client).getMeta();

// メタデータを強制更新
final freshMeta = await MetaClient(client).getMeta(refresh: true);

// 読み取り系POST（`i`は自動注入）
final list = await client.send<List<dynamic>>(
  '/notes/timeline',
  body: {'limit': 10},
  options: const RequestOptions(idempotent: true),
);

// 派生サービス用にベースURLにアクセス（例: ストリーミング）
final origin = client.baseUrl;
```

サンプルアプリ（`/example`）では、`misskey_auth` を使った認証、ノート投稿、ホームタイムライン、フォロー中/フォロワーの取得まで一通り確認できます。

### ライセンス

このプロジェクトは司書(LibraryLibrarian)によって、3-Clause BSD Licenseの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。
