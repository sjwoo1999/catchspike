class Logger {
  static void log(String message) {
    print(message); // 개발 환경에서는 print 사용
  }

  static void error(String message, [dynamic error]) {
    print('Error: $message');
    if (error != null) {
      print('Details: $error');
    }
  }

  static void info(String message) {
    print('Info: $message');
  }

  static void debug(String message) {
    print('Debug: $message');
  }

  static void warning(String message) {
    print('Warning: $message');
  }
}
