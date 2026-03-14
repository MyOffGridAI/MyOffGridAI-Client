/// Typed exception for API errors from the MyOffGridAI server.
///
/// Wraps HTTP status code, server message, and optional validation errors
/// into a single exception type for consistent error handling.
class ApiException implements Exception {
  /// The HTTP status code returned by the server.
  final int statusCode;

  /// The error message from the server or a default description.
  final String message;

  /// Optional map of field-level validation errors.
  final Map<String, dynamic>? errors;

  /// Creates an [ApiException] with the given [statusCode], [message],
  /// and optional [errors].
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
