/// Typed application exceptions with user-safe messages.
///
/// [AppException.message] is always safe to display to an end user: it never
/// contains stack traces, raw provider payloads, or API keys. The original
/// error identity is kept in [code] / [cause] for developer debugging.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  /// Human-readable, user-safe message.
  final String message;

  /// Original machine-readable error code, if any (never a secret).
  final String? code;

  /// The underlying error object, kept for debugging only.
  final Object? cause;

  @override
  String toString() => message;
}

enum AuthFailureType {
  invalidEmail,
  invalidCredentials,
  emailInUse,
  weakPassword,
  accountDisabled,
  tooManyRequests,
  network,
  operationNotAllowed,
  unknown,
}

class AuthException extends AppException {
  const AuthException(
    super.message, {
    required this.type,
    super.code,
    super.cause,
  });

  final AuthFailureType type;
}

enum FirestoreFailureType {
  permissionDenied,
  unauthenticated,
  unavailable,
  notFound,
  failedPrecondition,
  deadlineExceeded,
  quotaExceeded,
  unknown,
}

class FirestoreException extends AppException {
  const FirestoreException(
    super.message, {
    required this.type,
    super.code,
    super.cause,
  });

  final FirestoreFailureType type;
}

enum AIRequestFailureType {
  invalidBaseUrl,
  unauthorized,
  forbidden,
  rateLimited,
  timeout,
  network,
  serverError,
  malformedResponse,
  emptyResponse,
  unsupportedResponseFormat,
  unknown,
}

class AIRequestException extends AppException {
  const AIRequestException(
    super.message, {
    required this.type,
    super.code,
    super.cause,
  });

  final AIRequestFailureType type;
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.field, super.cause});

  /// Optional identifier of the offending form field.
  final String? field;
}

/// Fallback for unmapped errors.
class UnknownAppException extends AppException {
  const UnknownAppException(super.message, {super.code, super.cause});
}

/// Secure-storage read/write failures.
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}
