import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/initials_avatar.dart';

/// Profile: initials avatar, name, email, member-since, and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Sign out?',
      message: 'You will need to sign in again to access your conversations.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AppAuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AppAuthProvider>().user;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              InitialsAvatar(initials: user?.initials ?? '?', size: 88),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'User',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Member since'),
                      subtitle: Text(
                        DateTimeUtils.formatFullTimestamp(user?.createdAt),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.tag_outlined),
                      title: const Text('Account ID'),
                      subtitle: Text(
                        (user?.uid ?? '').isEmpty
                            ? '---'
                            : '${user!.uid.substring(0, 8)}...',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.apps_outlined),
                      title: const Text('App version'),
                      subtitle: const Text(AppConstants.appVersion),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
