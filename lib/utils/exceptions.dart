// lib/utils/exceptions.dart

class OpenAIException implements Exception {
  final String message;
  final String? code;

  const OpenAIException(this.message, {this.code});

  @override
  String toString() {
    if (code != null) {
      return 'OpenAIException: $message (Code: $code)';
    }
    return 'OpenAIException: $message';
  }
}
