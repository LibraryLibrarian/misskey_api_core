import 'package_logger.dart';

/// シンプルなロガーIF。必要に応じて差し替え可能
abstract class Logger {
  void debug(String message);
  void info(String message);
  void warn(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

class StdoutLogger implements Logger {
  const StdoutLogger();

  @override
  void debug(String message) {
    coreLog.d(message);
  }

  @override
  void info(String message) {
    coreLog.i(message);
  }

  @override
  void warn(String message) {
    coreLog.w(message);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (error != null || stackTrace != null) {
      coreLog.e(message, error: error, stackTrace: stackTrace);
    } else {
      coreLog.e(message);
    }
  }
}
