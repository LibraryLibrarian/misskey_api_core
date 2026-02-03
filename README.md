# misskey_api_core

[![Pub package](https://img.shields.io/pub/v/misskey_api_core.svg)](https://pub.dev/packages/misskey_api_core)
[![GitHub License](https://img.shields.io/badge/License-BSD-green.svg)](LICENSE)

A base library that wraps the MisskeyAPI created with Dart.

[日本語](#日本語)

## Overview

Misskey API Core is a pure Dart "foundation" library for interacting with Misskey servers. It was primarily created to standardize common functionality when using other Misskey features via API for my own use, but due to its versatility, I'm publishing it on pub.dev as a learning experience in library publication. It focuses on HTTP foundation, unified error handling, automatic token injection, and minimal common models (e.g., Meta), with domain-specific features (Notes/Users/Drive) designed to be implemented in separate layers.

## Key Features

- HTTP foundation: base URL handling (/api), timeouts, idempotent retries (429/5xx/network), request/response logging (debug-only)
- Multipart uploads: `FormData` support with auto token injection and upload progress callback (`onSendProgress`)
- Base URL exposure: access original base URL via `client.baseUrl` for derived services
- Auth token injection: automatically injects `i` into POST JSON bodies when `authRequired` is true
- Flexible token providers: support both sync and async token sources via `FutureOr<String?>`
- Unified error: normalize Misskey error response to `MisskeyApiException(statusCode/code/message)`
- Customizable error handling: map exceptions via `exceptionMapper` for unified error policies
- Flexible logging: use `loggerFn` for function-style logging or existing `Logger` interface
- Meta capability: `/api/meta` client with a tiny cache and `supports()` helper
- Meta refresh: force-refresh cached meta data with `getMeta(refresh: true)`
- JSON serialization: `json_serializable`-ready common model(s)

## Install

Add to `pubspec.yaml`:

```yaml
dependencies:
  misskey_api_core: ^0.0.3-beta
```

Then:

```bash
flutter pub get
```

## Quick Start

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

  // Multipart upload (e.g., Drive files/create)
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile('/path/to/image.png', filename: 'image.png'),
    // `i` is auto-injected when authRequired=true (default)
  });
  await client.send<Map<String, dynamic>>(
    '/drive/files/create',
    body: formData,
    onSendProgress: (sent, total) {
      // update UI progress
    },
  );

  // Per-request overrides
  await client.send(
    '/some/endpoint',
    body: {'a': 1},
    options: const RequestOptions(
      contentType: 'application/json; charset=utf-8',
      headers: {'X-Foo': 'bar'},
      extra: {'traceId': 'abc-123'},
    ),
  );

  // Handle 429 Retry-After
  try {
    await client.send('/rate-limited');
  } on MisskeyApiException catch (e) {
    if (e.statusCode == 429 && e.retryAfter != null) {
      await Future.delayed(e.retryAfter!);
    }
  }
  
  // Access base URL for derived services (e.g., streaming)
  final origin = client.baseUrl;
}
```

See `/example` for a working app including sign-in (with `misskey_auth`), posting a note, timelines, following/followers.

## License

This project is published by 司書 (LibraryLibrarian) under the 3-Clause BSD License. For details, please see the [LICENSE](LICENSE) file.

---

# 日本語

## 概要

MisskeyAPICoreは、Misskeyサーバーと連携するための純Dart“基盤”ライブラリです。主に自分自身が利用する他のMisskeyの機能をAPI経由で利用する際に共通化が必要な為作成しましたが、汎用性がある為ライブラリの公開という経験も兼ねてpub.devにて公開を行っています。HTTP基盤、共通例外、トークン自動付与、最低限の共通モデル（例: Meta）にフォーカスし、ノート/ユーザー/Driveなどドメイン固有機能は別レイヤーで実装できるように設計しています。

## 機能

- HTTP基盤: ベースURL（/api付与）・タイムアウト・冪等時の自動リトライ（429/5xx/ネットワーク）・デバッグ時のみログ
- マルチパート: `FormData` によるアップロード対応（トークン自動注入・`onSendProgress` による進捗）
- ベースURL公開: `client.baseUrl` で元URLにアクセス（派生サービス用）
- 認証: POSTのJSONボディに `i` を自動注入（`authRequired`で制御）
- 柔軟なトークン供給: 同期・非同期両方に対応（`FutureOr<String?>`）
- 共通例外: Misskeyのエラーを `MisskeyApiException(statusCode/code/message)` に正規化
- カスタマイズ可能な例外処理: `exceptionMapper` で例外を一元変換
- 柔軟なログ出力: 関数ベースロガー（`loggerFn`）または既存Logger IF
- メタ/能力検出: `/api/meta` の取得と簡易キャッシュ、`supports()` ヘルパー
- メタ更新: `getMeta(refresh: true)` でキャッシュを強制更新
- JSONシリアライズ: `json_serializable`対応の共通モデル

## インストール

`pubspec.yaml` に追加:

```yaml
dependencies:
  misskey_api_core: ^0.0.3-beta
```

実行:

```bash
dart pub get
# またはFlutterプロジェクトの場合:
flutter pub get
```

## 使い方

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

// マルチパート（例: Drive files/create）
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile('/path/to/image.png', filename: 'image.png'),
  // `authRequired=true`（既定）のとき `i` は自動注入
});
await client.send<Map<String, dynamic>>(
  '/drive/files/create',
  body: formData,
  onSendProgress: (sent, total) {
    // 進捗UIの更新
  },
);

// リクエスト単位の上書き（Content-Type/ヘッダ/extra）
await client.send(
  '/some/endpoint',
  body: {'a': 1},
  options: const RequestOptions(
    contentType: 'application/json; charset=utf-8',
    headers: {'X-Foo': 'bar'},
    extra: {'traceId': 'abc-123'},
  ),
);

// 429時の待機（Retry-After）
try {
  await client.send('/rate-limited');
} on MisskeyApiException catch (e) {
  if (e.statusCode == 429 && e.retryAfter != null) {
    await Future.delayed(e.retryAfter!);
  }
}

// 派生サービス用にベースURLにアクセス（例: ストリーミング）
final origin = client.baseUrl;
```

サンプルアプリ（`/example`）では、`misskey_auth` を使った認証、ノート投稿、ホームタイムライン、フォロー中/フォロワーの取得まで一通り確認できます。

## ライセンス

このプロジェクトは司書(LibraryLibrarian)によって、3-Clause BSD Licenseの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。
