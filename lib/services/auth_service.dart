import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../models/app_user.dart';

/// Contract for authentication operations.
///
/// AppAuthProvider and tests depend on this interface, not on the Firebase
/// implementation, so widget tests run without a Firebase app.
abstract class AuthServiceBase {
  Stream<fb_auth.User?> get authStateChanges;
  fb_auth.User? get currentUser;

  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> resetPassword({required String email});

  Future<void> createUserProfile(AppUser profile);

  /// Reads `users/{uid}`, creating the document on first access.
  Future<AppUser> getOrCreateProfile(fb_auth.User user);
}

/// Firebase Authentication + user-profile service.
///
/// Screens never talk to FirebaseAuth/Firestore directly; every call goes
/// through here and every SDK error is converted into a typed, user-safe
/// [AppException] by [ErrorMapper].
class AuthService implements AuthServiceBase {
  AuthService({fb_auth.FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? fb_auth.FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final fb_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Stream of raw Firebase auth-state changes (used by AppAuthProvider).
  @override
  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// The signed-in Firebase user, if any.
  @override
  fb_auth.User? get currentUser => _auth.currentUser;

  /// Creates the account, then writes the profile document at `users/{uid}`
  /// with server timestamps. If profile creation fails, the account is
  /// deleted again so the user can cleanly retry sign-up.
  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          'Account creation failed. Please try again.',
          type: AuthFailureType.unknown,
        );
      }
      await user.updateDisplayName(fullName);
      final profile = AppUser(
        uid: user.uid,
        fullName: fullName,
        email: email,
        photoUrl: null,
      );
      try {
        await createUserProfile(profile);
      } catch (_) {
        // Roll back the Auth account so a failed retry doesn't leave a
        // profile-less user that can never sign in usefully.
        await _safeDeleteAccount(user);
        rethrow;
      }
      return profile;
    } on fb_auth.FirebaseAuthException catch (error) {
      debugPrint('FirebaseAuthException in signUp: code=${error.code}, message=${error.message}, plugin=${error.plugin}');
      throw ErrorMapper.mapAuth(error);
    } on AppException {
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in signUp: ${error.runtimeType} - $error');
      throw ErrorMapper.map(error);
    }
  }

  /// Signs the user in and returns their profile.
  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          'Sign-in failed. Please check your credentials.',
          type: AuthFailureType.invalidCredentials,
        );
      }
      return getOrCreateProfile(user);
    } on fb_auth.FirebaseAuthException catch (error) {
      throw ErrorMapper.mapAuth(error);
    } on AppException {
      rethrow;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Sends a password-reset email. Firebase does not reveal whether the
  /// address exists, so a generic success notice is always shown.
  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (error) {
      throw ErrorMapper.mapAuth(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Reads `users/{uid}`, creating the document on first access (e.g. for
  /// accounts created directly in the Firebase console).
  @override
  Future<AppUser> getOrCreateProfile(fb_auth.User user) async {
    final docRef = _firestore.doc(FirestorePaths.userDoc(user.uid));
    try {
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return AppUser.fromMap(snapshot.data()!);
      }
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    }
    final profile = AppUser(
      uid: user.uid,
      fullName: user.displayName ?? user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
    try {
      await createUserProfile(profile);
      return profile;
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    }
  }

  /// Writes the profile document with server timestamps.
  @override
  Future<void> createUserProfile(AppUser profile) async {
    try {
      debugPrint('Creating user profile for uid: ${profile.uid}');
      await _firestore.doc(FirestorePaths.userDoc(profile.uid)).set({
        'uid': profile.uid,
        'fullName': profile.fullName,
        'email': profile.email,
        'photoUrl': profile.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User profile created successfully');
    } on FirebaseException catch (error) {
      debugPrint('Firestore error in createUserProfile: code=${error.code}, message=${error.message}');
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      debugPrint('Unexpected error in createUserProfile: ${error.runtimeType} - $error');
      throw ErrorMapper.map(error);
    }
  }

  Future<void> _safeDeleteAccount(fb_auth.User user) async {
    try {
      await user.delete();
    } catch (_) {
      // Best-effort rollback only; surface the original profile error.
    }
  }
}
