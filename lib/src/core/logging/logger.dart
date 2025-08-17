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
    // ignore: avoid_print
    print('[DEBUG] $message');
  }

  @override
  void info(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }

  @override
  void warn(String message) {
    // ignore: avoid_print
    print('[WARN] $message');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[ERROR] $message${error != null ? ' error=$error' : ''}');
    if (stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}
