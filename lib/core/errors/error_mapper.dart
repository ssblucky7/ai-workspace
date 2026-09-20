import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;

import 'app_exception.dart';

/// Converts platform and SDK errors into typed, user-safe [AppException]s.
///
/// Raw SDK exceptions, stack traces, and provider payloads never reach the
/// UI; each mapping below produces a friendly message safe to display.
abstract final class ErrorMapper {
  static AppException map(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) return mapAuth(error);
    if (error is FirebaseException) return mapFirestore(error);
    if (error is TimeoutException) {
      return const AIRequestException(
        'The request timed out. Please try again.',
        type: AIRequestFailureType.timeout,
      );
    }
    if (error is FormatException) {
      return const AIRequestException(
        'Received an unexpected response format.',
        type: AIRequestFailureType.malformedResponse,
      );
    }
    return UnknownAppException(
      'Something went wrong (${error.runtimeType}). Please try again.',
      code: error.runtimeType.toString(),
      cause: error,
    );
  }

  static AuthException mapAuth(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return AuthException(
          'That email address looks invalid.',
          type: AuthFailureType.invalidEmail,
          code: error.code,
          cause: error,
        );
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return AuthException(
          'Incorrect email or password.',
          type: AuthFailureType.invalidCredentials,
          code: error.code,
          cause: error,
        );
      case 'email-already-in-use':
        return AuthException(
          'An account already exists with this email.',
          type: AuthFailureType.emailInUse,
          code: error.code,
          cause: error,
        );
      case 'weak-password':
        return AuthException(
          'Please choose a stronger password (at least 6 characters).',
          type: AuthFailureType.weakPassword,
          code: error.code,
          cause: error,
        );
      case 'user-disabled':
        return AuthException(
          'This account has been disabled. Please contact support.',
          type: AuthFailureType.accountDisabled,
          code: error.code,
          cause: error,
        );
      case 'too-many-requests':
        return AuthException(
          'Too many attempts. Please wait a moment and try again.',
          type: AuthFailureType.tooManyRequests,
          code: error.code,
          cause: error,
        );
      case 'network-request-failed':
        return AuthException(
          'Network error. Check your connection and try again.',
          type: AuthFailureType.network,
          code: error.code,
          cause: error,
        );
      case 'operation-not-allowed':
        return AuthException(
          'Email/password sign-in is not enabled for this Firebase project. '
          'Enable it in the Firebase console.',
          type: AuthFailureType.operationNotAllowed,
          code: error.code,
          cause: error,
        );
      case 'internal-error':
        return AuthException(
          'An internal error occurred. Please try again.',
          type: AuthFailureType.unknown,
          code: error.code,
          cause: error,
        );
      case 'timeout':
        return AuthException(
          'The request timed out. Please check your connection and try again.',
          type: AuthFailureType.network,
          code: error.code,
          cause: error,
        );
      case 'credential-already-in-use':
        return AuthException(
          'This credential is already associated with a different account.',
          type: AuthFailureType.emailInUse,
          code: error.code,
          cause: error,
        );
      case 'account-exists-with-different-credential':
        return AuthException(
          'An account already exists with the same email but different sign-in method. '
          'Sign in with that method first.',
          type: AuthFailureType.emailInUse,
          code: error.code,
          cause: error,
        );
      case 'requires-recent-login':
        return AuthException(
          'This operation requires recent authentication. Please sign in again.',
          type: AuthFailureType.invalidCredentials,
          code: error.code,
          cause: error,
        );
      default:
        // Include the error code AND original message for debugging unknown errors
        final originalMessage = error.message ?? 'no message';
        return AuthException(
          'Authentication failed (${error.code}): $originalMessage. '
          'Check Firebase Console: Authentication → Sign-in method → Email/Password enabled? '
          'Also verify google-services.json / firebase_options.dart match your project.',
          type: AuthFailureType.unknown,
          code: error.code,
          cause: error,
        );
    }
  }

  static FirestoreException mapFirestore(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return FirestoreException(
          'You do not have permission to access this data.',
          type: FirestoreFailureType.permissionDenied,
          code: error.code,
          cause: error,
        );
      case 'unauthenticated':
        return FirestoreException(
          'Your session has expired. Please sign in again.',
          type: FirestoreFailureType.unauthenticated,
          code: error.code,
          cause: error,
        );
      case 'unavailable':
        return FirestoreException(
          'Cannot reach the database. Check your connection and try again.',
          type: FirestoreFailureType.unavailable,
          code: error.code,
          cause: error,
        );
      case 'not-found':
        return FirestoreException(
          'This item no longer exists.',
          type: FirestoreFailureType.notFound,
          code: error.code,
          cause: error,
        );
      case 'failed-precondition':
        return FirestoreException(
          'The request could not be completed. If this persists, the required '
          'Firestore index may be missing.',
          type: FirestoreFailureType.failedPrecondition,
          code: error.code,
          cause: error,
        );
      case 'deadline-exceeded':
        return FirestoreException(
          'The database request timed out. Please try again.',
          type: FirestoreFailureType.deadlineExceeded,
          code: error.code,
          cause: error,
        );
      case 'resource-exhausted':
        return FirestoreException(
          'Service quota exceeded. Please try again later.',
          type: FirestoreFailureType.quotaExceeded,
          code: error.code,
          cause: error,
        );
      default:
        return FirestoreException(
          'A database error occurred. Please try again.',
          type: FirestoreFailureType.unknown,
          code: error.code,
          cause: error,
        );
    }
  }
}
