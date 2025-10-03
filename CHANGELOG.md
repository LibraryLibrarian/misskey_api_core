# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.4-beta] - 2025-10-03

### Fixed
- Improved error logging: Expected client errors (401/403/404) are now logged at `debug` level instead of `error` level to reduce noise in logs. This prevents cluttering logs with expected errors like unauthorized access or non-public resources.

### Update
- Update the flutterSDK version to 3.35.5.

## [0.0.3-beta] - 2025-09-13

### Added
- Added support for multipart/form-data uploads (`FormData`). When using POST and `authRequired=true`, the token `i` is automatically injected into `FormData` as well.
- `MisskeyHttpClient.send` now accepts a `dynamic body` (`Map`/`FormData`/`null`) and supports upload progress callbacks via `onSendProgress`.
- Added `contentType`, `headers`, and `extra` to `RequestOptions`, allowing per-request overrides.
- The `Retry-After` value on HTTP 429 is now captured in `MisskeyApiException.retryAfter`.

### Changed
- Removed the global `Content-Type: application/json`. Content-Type is now automatically inferred per request (or can be explicitly set via `RequestOptions.contentType`). `Accept: application/json` is still set globally.
- Improved token injection in the interceptor: the token `i` is now injected for all `Map`, `FormData`, and `null` bodies (when POST and `authRequired=true`).
- Existing error mapping is retained, but now includes the retry wait hint for 429 responses.

### Migration Notes
- Sending JSON works as before by passing `body: Map` (Dio will infer the Content-Type).
- If you previously relied on a global fixed `Content-Type`, please specify it via `RequestOptions.contentType` as needed.
- The signature of `send<T>` has been extended, but existing calls passing a `Map` will continue to work as before.

## [0.0.2-beta] - 2025-08-19

### Added
- Expose `MisskeyHttpClient.baseUrl` (original base, before `/api` normalization).
- Add `exceptionMapper` hook to `MisskeyHttpClient` to customize thrown exceptions.
- Add `loggerFn` (function-style logger) accepted by `MisskeyHttpClient` and adapt to existing `Logger` interface.
- `MetaClient.getMeta({bool refresh = false})` to force-refresh cache when needed.

### Changed
- Generalize `TokenProvider` to `FutureOr<String?> Function()` to support both sync/async token sources.

## [0.0.1-beta] - 2025-08-18

### Added
- HTTP foundation using Dio: base URL handling (appends `/api`), timeouts, and idempotent retries (429/5xx/network) with jitter via `retry`.
- Request/response logging (debug-only).
- Unified error handling: map Misskey error responses to `MisskeyApiException(statusCode/code/message)`.
- Auth token auto-injection: inject `i` into POST JSON bodies when `authRequired` is true; per-request options via `RequestOptions(authRequired/idempotent)`.
- Minimal common model and client for `/api/meta` (Meta + MetaClient), including a tiny cache and `supports(keyPath)` capability detection.
- JSON serialization setup (`json_serializable`/`json_annotation`) and generated code.
- Example app (`example/`): sign-in using `misskey_auth`, note posting, timeline, following/followers tabs; Riverpod for state; `loader_overlay` for loading UI.
- OAuth helper site under `pages/` (`index.html`, `redirect.html`) and GitHub Pages deploy workflow (`.github/workflows/deploy-pages.yml`).
- Android/ iOS URL-scheme setup for OAuth callback; Android `INTERNET` permission.
- Unit tests: token injection, error mapping, retry behavior, and Meta serialization/capability; example smoke test.