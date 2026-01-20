/// API Exception
///
/// Custom exception class for handling API errors throughout the app.
/// Provides structured error information for consistent error handling.
class ApiException implements Exception {
  /// Error message to display to users
  final String message;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Error code from API (if applicable)
  final String? errorCode;

  /// Validation errors map (field -> list of errors)
  final Map<String, List<String>>? validationErrors;

  /// Raw response data (for debugging)
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.validationErrors,
    this.data,
  });

  /// Create from API response
  factory ApiException.fromResponse({
    required int statusCode,
    required dynamic body,
  }) {
    String message = 'Something went wrong. Please try again.';
    String? errorCode;
    Map<String, List<String>>? validationErrors;

    if (body is Map<String, dynamic>) {
      // Extract message
      message = body['message'] as String? ??
          body['error'] as String? ??
          message;

      // Extract error code
      errorCode = body['code'] as String?;

      // Extract validation errors (Laravel format)
      if (body['errors'] is Map<String, dynamic>) {
        validationErrors = {};
        final errors = body['errors'] as Map<String, dynamic>;
        errors.forEach((key, value) {
          if (value is List) {
            validationErrors![key] = value.cast<String>();
          } else if (value is String) {
            validationErrors![key] = [value];
          }
        });
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      validationErrors: validationErrors,
      data: body,
    );
  }

  /// Network error (no internet, timeout, etc.)
  factory ApiException.network([String? message]) {
    return ApiException(
      message: message ?? 'Network error. Please check your connection.',
      errorCode: 'NETWORK_ERROR',
    );
  }

  /// Timeout error
  factory ApiException.timeout() {
    return const ApiException(
      message: 'Request timed out. Please try again.',
      errorCode: 'TIMEOUT',
    );
  }

  /// Unauthorized error (401)
  factory ApiException.unauthorized([String? message]) {
    return ApiException(
      message: message ?? 'Session expired. Please login again.',
      statusCode: 401,
      errorCode: 'UNAUTHORIZED',
    );
  }

  /// Forbidden error (403)
  factory ApiException.forbidden([String? message]) {
    return ApiException(
      message: message ?? 'You do not have permission to perform this action.',
      statusCode: 403,
      errorCode: 'FORBIDDEN',
    );
  }

  /// Not found error (404)
  factory ApiException.notFound([String? message]) {
    return ApiException(
      message: message ?? 'The requested resource was not found.',
      statusCode: 404,
      errorCode: 'NOT_FOUND',
    );
  }

  /// Validation error (422)
  factory ApiException.validation({
    String? message,
    Map<String, List<String>>? errors,
  }) {
    return ApiException(
      message: message ?? 'Please check your input and try again.',
      statusCode: 422,
      errorCode: 'VALIDATION_ERROR',
      validationErrors: errors,
    );
  }

  /// Server error (500+)
  factory ApiException.server([String? message]) {
    return ApiException(
      message: message ?? 'Server error. Please try again later.',
      statusCode: 500,
      errorCode: 'SERVER_ERROR',
    );
  }

  /// Unknown error
  factory ApiException.unknown([String? message]) {
    return ApiException(
      message: message ?? 'An unexpected error occurred.',
      errorCode: 'UNKNOWN',
    );
  }

  /// Check if this is an authentication error
  bool get isAuthError => statusCode == 401 || errorCode == 'UNAUTHORIZED';

  /// Check if this is a validation error
  bool get isValidationError =>
      statusCode == 422 || errorCode == 'VALIDATION_ERROR';

  /// Check if this is a network error
  bool get isNetworkError => errorCode == 'NETWORK_ERROR' || errorCode == 'TIMEOUT';

  /// Check if this is a server error
  bool get isServerError => (statusCode ?? 0) >= 500;

  /// Get first validation error for a field
  String? getFieldError(String field) {
    return validationErrors?[field]?.firstOrNull;
  }

  /// Get all validation errors as a single string
  String? get allValidationErrors {
    if (validationErrors == null || validationErrors!.isEmpty) return null;

    final errors = <String>[];
    validationErrors!.forEach((field, messages) {
      errors.addAll(messages);
    });
    return errors.join('\n');
  }

  @override
  String toString() {
    return 'ApiException: $message (statusCode: $statusCode, errorCode: $errorCode)';
  }
}
