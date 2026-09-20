import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// About: identity, description, technology stack, implemented scope,
/// security notice, and future enhancements.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hub_outlined,
                  size: 44,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version ${AppConstants.appVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _card(
          context,
          icon: Icons.description_outlined,
          title: 'What this app is',
          child: Text(
            'AI Workspace is an academic Flutter project demonstrating '
            'Firebase Authentication, Cloud Firestore real-time CRUD, '
            'Provider state management, custom Material 3 theming, and '
            'an optional OpenAI-compatible chat layer.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        _card(
          context,
          icon: Icons.layers_outlined,
          title: 'Technologies used',
          child: Text(
            'Flutter & Dart (null-safe) ... Material 3 ... Firebase Core, '
            'Authentication, Cloud Firestore ... Provider ... GoRouter ... '
            'SharedPreferences ... flutter_secure_storage ... HTTP ... Intl',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        _card(
          context,
          icon: Icons.check_circle_outline,
          title: 'Implemented in this version',
          child: Text(
            '... Email/password sign-up, sign-in, password reset, sign-out\n'
            '... Persistent sessions and protected screens\n'
            '... Real-time conversation and message streams (CRUD)\n'
            '... User-configured OpenAI-compatible providers\n'
            '... Secure local API-key storage (never synced)\n'
            '... Model fetching and selection\n'
            '... Light / dark / system themes\n'
            '... Responsive navigation (bar/rail)\n'
            '... Form validation, loading/empty/error states, confirmations',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        _card(
          context,
          icon: Icons.security_outlined,
          title: 'Privacy and API keys',
          child: Text(
            'Conversations are stored in Cloud Firestore under your own '
            'account path and protected by security rules. Provider API '
            'keys are stored only in this device\'s secure storage, are '
            'never uploaded to Firestore, and are always displayed '
            'masked. A production deployment should route AI requests '
            'through a trusted backend to protect credentials.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        _card(
          context,
          icon: Icons.upcoming_outlined,
          title: 'Future enhancements (coming soon)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final feature in AppConstants.futureEnhancements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '... ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Built as an academic assignment. Not affiliated with any '
            'AI vendor.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
