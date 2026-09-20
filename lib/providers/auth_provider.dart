import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Authentication state for the whole app.
///
/// Wraps the auth service contract and exposes sign-up / sign-in /
/// sign-out / password-reset plus the parsed [AppUser] profile. Named
/// `AppAuthProvider` to avoid ambiguity with the `provider` package.
class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({required AuthServiceBase authServiceBase})
    : _authService = authServiceBase;

  final AuthServiceBase _authService;

  StreamSubscription<fb_auth.User?>? _authSubscription;

  /// True until the first auth-state event resolves from Firebase.
  bool _initializing = true;
  bool get initializing => _initializing;

  AppUser? _user;
  AppUser? get user => _user;

  /// Convenience flag: any signed-in user.
  bool get isSignedIn => _user != null;

  /// Loading flag for in-flight sign-up / sign-in / reset operations.
  bool _busy = false;
  bool get busy => _busy;

  /// Last user-safe error message for auth flows (cleared on each action).
  String? _error;
  String? get error => _error;

  /// Attaches to Firebase's persistent auth state. Called once from main().
  void start() {
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen(
      (fbUser) async {
        if (fbUser == null) {
          _user = null;
          _initializing = false;
          notifyListeners();
          return;
        }
        try {
          _user = await _loadProfile(fbUser);
        } catch (error) {
          // Authenticated but profile unreadable: still signed in, with a
          // minimal profile so protected screens keep working.
          _user = AppUser(
            uid: fbUser.uid,
            fullName: fbUser.displayName ?? 'User',
            email: fbUser.email ?? '',
          );
        }
        _initializing = false;
        notifyListeners();
      },
      onError: (Object error) {
        _initializing = false;
        _error = _safeMessage(error);
        notifyListeners();
      },
    );
  }

  Future<AppUser> _loadProfile(fb_auth.User fbUser) async {
    final profile = await _authService.getOrCreateProfile(fbUser);
    return profile;
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Returns true on success. On failure [error] holds a user-safe message.
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_busy) return false; // prevent duplicate submissions
    _setBusy(true);
    _error = null;
    try {
      await _authService.signUp(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
      );
      return true;
    } on AppException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = _safeMessage(error);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_busy) return false;
    _setBusy(true);
    _error = null;
    try {
      await _authService.signIn(email: email.trim(), password: password);
      return true;
    } on AppException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = _safeMessage(error);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> resetPassword({required String email}) async {
    if (_busy) return false;
    _setBusy(true);
    _error = null;
    try {
      await _authService.resetPassword(email: email.trim());
      return true;
    } on AppException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = _safeMessage(error);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Signs out and clears profile state. Called after confirmation.
  Future<void> signOut() async {
    _error = null;
    try {
      await _authService.signOut();
    } on AppException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = _safeMessage(error);
    }
    notifyListeners();
  }

  String _safeMessage(Object error) {
    if (error is AppException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
