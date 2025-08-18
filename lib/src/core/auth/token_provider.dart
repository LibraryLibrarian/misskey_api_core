import 'dart:async';

/// 認可トークンを提供するための型
/// 同期/非同期のいずれにも対応できるように `FutureOr<String?>` を返す関数型を利用する想定
typedef TokenProvider = FutureOr<String?> Function();
