import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';

import 'package:ai_workspace/core/errors/app_exception.dart';
import 'package:ai_workspace/core/routing/route_names.dart';
import 'package:ai_workspace/models/app_user.dart';
import 'package:ai_workspace/providers/auth_provider.dart';
import 'package:ai_workspace/screens/auth/sign_in_screen.dart';
import 'package:ai_workspace/services/auth_service.dart';

/// Minimal fake of the auth service contract used by the sign-in form. The
/// screen only calls `signIn` here, so no Firebase backend is exercised —
/// implementing AuthServiceBase avoids the Firebase constructor entirely.
class FakeAuthService implements AuthServiceBase {
  int signInCalls = 0;

  @override
  Stream<fb_auth.User?> get authStateChanges => const Stream.empty();

  @override
  fb_auth.User? get currentUser => null;

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return AppUser(uid: 'x', fullName: fullName, email: email);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    throw AuthException(
      'Incorrect email or password.',
      type: AuthFailureType.invalidCredentials,
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> createUserProfile(AppUser profile) async {}

  @override
  Future<AppUser> getOrCreateProfile(fb_auth.User user) async {
    return AppUser(uid: user.uid, fullName: 'User', email: user.email ?? '');
  }
}

void main() {
  Widget buildScreen({AuthServiceBase? authService}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppAuthProvider(
            authServiceBase: authService ?? FakeAuthService(),
          ),
        ),
      ],
      child: const MaterialApp(home: SignInScreen()),
    );
  }

  testWidgets('renders all sign-in fields', (tester) async {
    await tester.pumpWidget(buildScreen());
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('shows field errors on empty submission', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter a password.'), findsOneWidget);
  });

  testWidgets('rejects an invalid email with a friendly message', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('password visibility toggle works', (tester) async {
    await tester.pumpWidget(buildScreen());
    final passwordField = find.byType(TextFormField).last;
    await tester.enterText(passwordField, 'secret12');

    TextField inner = tester.widget<TextField>(
      find.descendant(of: passwordField, matching: find.byType(TextField)),
    );
    expect(inner.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    inner = tester.widget<TextField>(
      find.descendant(of: passwordField, matching: find.byType(TextField)),
    );
    expect(inner.obscureText, isFalse);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    inner = tester.widget<TextField>(
      find.descendant(of: passwordField, matching: find.byType(TextField)),
    );
    expect(inner.obscureText, isTrue);
  });

  testWidgets('valid input reaches the auth service and surfaces its error', (
    tester,
  ) async {
    final fake = FakeAuthService();
    await tester.pumpWidget(buildScreen(authService: fake));
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    // Let the async sign-in complete and the SnackBar appear.
    await tester.pump(const Duration(milliseconds: 300));

    expect(fake.signInCalls, 1);
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  test('route constants match the intended paths', () {
    expect(RouteNames.signUpPath, '/sign-up');
    expect(RouteNames.signInPath, '/sign-in');
  });
}
