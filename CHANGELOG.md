# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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