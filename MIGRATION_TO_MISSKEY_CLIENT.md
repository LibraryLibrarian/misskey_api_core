# Migrating to misskey_client / misskey_client への移行

`misskey_api_core` is deprecated. Its HTTP foundation, configuration,
authentication, logging, error handling, and Meta API are available in
[`misskey_client`](https://pub.dev/packages/misskey_client).

`misskey_api_core` は非推奨です。HTTP基盤、設定、認証、ログ、例外処理、
Meta APIは [`misskey_client`](https://pub.dev/packages/misskey_client) へ
移行されています。

Existing `misskey_api_core` releases remain published and are not retracted,
so migration can be performed incrementally.

公開済みの `misskey_api_core` はretractされないため、段階的に移行できます。

## Dependencies and imports / 依存とimport

Replace the package dependency:

```yaml
dependencies:
  misskey_client: ^1.0.0-beta.7
```

Replace the import:

```dart
// Before
import 'package:misskey_api_core/misskey_api_core.dart';

// After
import 'package:misskey_client/misskey_client.dart';
```

## API mapping / API対応表

| `misskey_api_core` | `misskey_client` |
|---|---|
| `MisskeyHttpClient` | `MisskeyClient` |
| `MisskeyApiConfig` | `MisskeyClientConfig` |
| `TokenProvider` | `TokenProvider` |
| `MetaClient(http).getMeta()` | `client.meta.getMeta()` |
| `MetaClient(http).getMeta(refresh: true)` | `client.meta.getMeta(refresh: true)` |
| `RequestOptions(authRequired: false)` | `RequestOptions(authMode: AuthMode.none)` |
| `RequestOptions(authRequired: true)` | `RequestOptions(authMode: AuthMode.required)` |
| `MisskeyApiException` | `MisskeyApiException` and the typed exception subclasses |
| `Logger` / `FunctionLogger` / `StdoutLogger` | Classes with the same names |

## Client setup / クライアント生成

```dart
// Before
final http = MisskeyHttpClient(
  config: MisskeyApiConfig(
    baseUrl: Uri.parse('https://misskey.example.com'),
  ),
  tokenProvider: () => token,
);

// After
final client = MisskeyClient(
  config: MisskeyClientConfig(
    baseUrl: Uri.parse('https://misskey.example.com'),
  ),
  tokenProvider: () => token,
);
```

Use the typed API domains exposed by `MisskeyClient` instead of constructing
domain clients around `MisskeyHttpClient`.

`MisskeyHttpClient` を利用側で組み立てる代わりに、`MisskeyClient` が公開する
型付きAPIドメインを利用してください。

```dart
// Before
final meta = await MetaClient(http).getMeta();

// After
final meta = await client.meta.getMeta();
```

## Low-level requests / 低レベルリクエスト

`MisskeyHttpClient.send<T>()` has no public one-to-one replacement.
`misskey_client` intentionally keeps its HTTP implementation internal. Use a
typed API method. If an upstream Misskey endpoint is missing, request or add a
typed implementation in `misskey_client`.

`MisskeyHttpClient.send<T>()` と一対一で対応する公開APIはありません。
`misskey_client` はHTTP実装を意図的に内部へ閉じています。型付きAPIを使用し、
未実装のMisskeyエンドポイントが必要な場合は `misskey_client` に型付き実装を
追加してください。

## Exceptions / 例外

Both packages export a class named `MisskeyApiException`, but the classes are
different. During an incremental migration, prefix the imports:

両パッケージには同名の `MisskeyApiException` が存在しますが、異なるクラスです。
段階的な移行中に両方をimportする場合はprefixを付けてください。

```dart
import 'package:misskey_api_core/misskey_api_core.dart' as legacy;
import 'package:misskey_client/misskey_client.dart' as current;
```

The `misskey_client` exception hierarchy derives from
`MisskeyClientException` and provides typed exceptions such as
`MisskeyUnauthorizedException`, `MisskeyForbiddenException`, and
`MisskeyRateLimitException`.

## Build mode constants / ビルドモード定数

`kReleaseMode` and `kDebugMode` are not exported by `misskey_client`. In a
Flutter application use `package:flutter/foundation.dart`. In pure Dart, use
`bool.fromEnvironment('dart.vm.product')` where required.

`kReleaseMode` と `kDebugMode` は `misskey_client` からexportされません。
Flutterアプリでは `package:flutter/foundation.dart`、pure Dartでは必要に応じて
`bool.fromEnvironment('dart.vm.product')` を利用してください。

## Migration checklist / 移行チェックリスト

1. Replace the dependency and import.
2. Replace `MisskeyApiConfig` with `MisskeyClientConfig`.
3. Create one `MisskeyClient` and reuse it across API domains.
4. Replace `MetaClient` and raw `send<T>()` calls with typed API methods.
5. Update exception handling to the `MisskeyClientException` hierarchy.
6. Remove the `misskey_api_core` dependency after every call site is migrated.

1. 依存とimportを置き換える。
2. `MisskeyApiConfig` を `MisskeyClientConfig` に置き換える。
3. 1つの `MisskeyClient` を生成し、APIドメイン間で共有する。
4. `MetaClient` と低レベル `send<T>()` を型付きAPIへ置き換える。
5. 例外処理を `MisskeyClientException` 階層へ移行する。
6. 全呼び出し箇所の移行後に `misskey_api_core` 依存を削除する。
