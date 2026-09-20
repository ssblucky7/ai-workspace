import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/ai_provider_config.dart';
import '../../providers/auth_provider.dart';
import '../../screens/about/about_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/sign_in_screen.dart';
import '../../screens/auth/sign_up_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/conversations/conversation_history_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/providers/add_edit_provider_screen.dart';
import '../../screens/providers/ai_providers_screen.dart';
import '../../screens/providers/model_selection_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../widgets/responsive_scaffold.dart';
import 'route_names.dart';

/// Arguments passed to the model-selection route.
class ModelSelectionArgs {
  const ModelSelectionArgs({required this.draft, this.apiKey = ''});

  /// Current draft provider configuration being edited.
  final AIProviderConfig draft;
  final String apiKey;
}

/// The authenticated shell that provides responsive navigation (bottom bar / rail).
class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(body: child);
  }
}

/// Application router with a global redirect enforcing authentication:
///
/// - While auth state is initializing, stay on the splash screen.
/// - Unauthenticated users are sent to Sign In.
/// - Authenticated users are kept out of Sign In / Sign Up / Forgot Password.
/// - The redirect is idempotent, preventing redirect loops.
GoRouter buildAppRouter(AppAuthProvider authProvider) {
  return GoRouter(
    initialLocation: RouteNames.splashPath,
    refreshListenable: authProvider,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final initializing = authProvider.initializing;
      final signedIn = authProvider.isSignedIn;
      final path = state.matchedLocation;

      // 1. While the persistent Firebase session is still being restored,
      //    hold the user on the splash screen.
      if (initializing) {
        return path == RouteNames.splashPath ? null : RouteNames.splashPath;
      }

      // 2. Auth state resolved: never stay on splash — always leave it.
      if (path == RouteNames.splashPath) {
        return signedIn
            ? RouteNames.homePath
            : RouteNames.signInPath;
      }

      // 3. Unauthenticated users may only access the auth screens.
      final isAuthRoute = path == RouteNames.signInPath ||
          path == RouteNames.signUpPath ||
          path == RouteNames.forgotPasswordPath;
      if (!signedIn && !isAuthRoute) {
        return RouteNames.signInPath;
      }

      // 4. Signed-in users never go back to auth screens.
      if (signedIn && isAuthRoute) {
        return RouteNames.homePath;
      }
      return null;
    },
    routes: [
      GoRoute(
        name: RouteNames.splash,
        path: RouteNames.splashPath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: RouteNames.signIn,
        path: RouteNames.signInPath,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        name: RouteNames.signUp,
        path: RouteNames.signUpPath,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        name: RouteNames.forgotPassword,
        path: RouteNames.forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Chat screen needs its own Scaffold with custom AppBar (conversation actions)
      GoRoute(
        name: RouteNames.chat,
        path: RouteNames.chatPath,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          final isNewChat = conversationId == 'new' || conversationId.isEmpty;
          return ChatScreen(conversationId: isNewChat ? null : conversationId);
        },
      ),
      // Authenticated shell with responsive navigation
      ShellRoute(
        builder: (context, state, child) => AuthenticatedShell(child: child),
        routes: [
          GoRoute(
            name: RouteNames.home,
            path: RouteNames.homePath,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            name: RouteNames.conversationHistory,
            path: RouteNames.conversationHistoryPath,
            builder: (context, state) => const ConversationHistoryScreen(),
          ),
          GoRoute(
            name: RouteNames.aiProviders,
            path: RouteNames.aiProvidersPath,
            builder: (context, state) => const AIProvidersScreen(),
            routes: [
              GoRoute(
                name: RouteNames.addEditProvider,
                path: 'edit',
                builder: (context, state) {
                  final provider = state.extra as AIProviderConfig?;
                  return AddEditProviderScreen(existing: provider);
                },
              ),
              GoRoute(
                name: RouteNames.modelSelection,
                path: 'model-selection',
                builder: (context, state) {
                  final args = state.extra as ModelSelectionArgs?;
                  if (args == null) {
                    return const AIProvidersScreen();
                  }
                  return ModelSelectionScreen(
                    draft: args.draft,
                    apiKey: args.apiKey,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: RouteNames.settings,
            path: RouteNames.settingsPath,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            name: RouteNames.profile,
            path: RouteNames.profilePath,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            name: RouteNames.about,
            path: RouteNames.aboutPath,
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const SplashScreen(),
  );
}
