import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/ai_provider_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/initials_avatar.dart';

/// Settings: theme selection (light/dark/system), active AI provider and
/// model summary, navigation to providers/profile/about, and sign out with
/// confirmation.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Sign out?',
      message:
          'You will need to sign in again to access your '
          'conversations.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AppAuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final providerState = context.watch<AIProviderConfigProvider>();
    final auth = context.watch<AppAuthProvider>();
    final activeProvider = providerState.activeProvider;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _sectionHeader(context, 'Appearance'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              RadioGroup<ThemeMode>(
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    context.read<ThemeProvider>().setThemeMode(mode);
                  }
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: Text('Follow system'),
                      subtitle: Text('Matches your device setting'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: Text('Light'),
                      subtitle: Text('Warm neutral background'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: Text('Dark'),
                      subtitle: Text('Charcoal with indigo accents'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _sectionHeader(context, 'AI provider'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.dns_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  activeProvider == null
                      ? 'No provider configured'
                      : activeProvider.name,
                ),
                subtitle: Text(
                  activeProvider?.selectedModel ??
                      'Connect an OpenAI-compatible provider to generate '
                          'replies',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouteNames.aiProvidersPath),
              ),
            ],
          ),
        ),
        _sectionHeader(context, 'Account'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: InitialsAvatar(
                  initials: auth.user?.initials ?? '?',
                  size: 36,
                ),
                title: Text(auth.user?.fullName ?? 'Profile'),
                subtitle: Text(auth.user?.email ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouteNames.profilePath),
              ),
            ],
          ),
        ),
        _sectionHeader(context, 'About'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('About AI Workspace'),
                subtitle: const Text(
                  'Technologies, privacy notice, and future plans',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouteNames.aboutPath),
              ),
              ListTile(
                leading: Icon(
                  Icons.verified_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Version'),
                subtitle: const Text(AppConstants.appVersion),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
