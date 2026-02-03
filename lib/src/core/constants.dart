/// Dart環境でのビルドモード検出用定数
///
/// Flutterの `kDebugMode` / `kReleaseMode` と同等の機能を純Dartで提供
library;

/// リリースモードかどうかを示す定数
///
/// `dart.vm.product` フラグが `true` の場合に `true` を返す
/// コンパイル時定数として評価されるため、リリースビルドでは
/// デバッグコードが完全に削除される（tree-shaking）
///
/// ## ビルドモードの判定
///
/// - デバッグビルド: `dart run`、`flutter run` → false
/// - リリースビルド: `dart compile exe -Ddart.vm.product=true`、
///   `flutter build --release` → true
///
/// ## 使用例
///
/// ```dart
/// if (!kReleaseMode) {
///   print('This code is removed in release builds');
/// }
/// ```
const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// デバッグモードかどうかを示す定数
///
/// リリースモードでない場合に `true` を返す
/// コンパイル時定数として評価されるため、リリースビルドでは
/// デバッグコードが完全に削除される（tree-shaking）
///
/// ## 使用例
///
/// ```dart
/// if (kDebugMode) {
///   logger.debug('Debug information');
/// }
/// ```
const bool kDebugMode = !kReleaseMode;
