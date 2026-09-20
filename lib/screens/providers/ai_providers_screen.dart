import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/route_names.dart';
import '../../core/routing/app_router.dart' show ModelSelectionArgs;
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/utils/api_key_masker.dart';
import '../../models/ai_provider_config.dart';
import '../../providers/ai_provider_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/provider_card.dart';

/// List of configured AI providers with activate / test / fetch-models /
/// edit / delete actions.
class AIProvidersScreen extends StatefulWidget {
  const AIProvidersScreen({super.key});

  @override
  State<AIProvidersScreen> createState() => _AIProvidersScreenState();
}

class _AIProvidersScreenState extends State<AIProvidersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AppAuthProvider>();
      if (!auth.initializing && auth.isSignedIn) {
        context.read<AIProviderConfigProvider>().startListening(auth.user!.uid);
      }
    });
  }

  Future<void> _delete(AIProviderConfig provider) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete provider?',
      message:
          '"${provider.name}" will be removed together with its saved API '
          'key. Conversations are not affected.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final ok = await context.read<AIProviderConfigProvider>().deleteProvider(
      provider: provider,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Provider deleted' : 'Could not delete provider'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _activate(AIProviderConfig provider) async {
    final auth = context.read<AppAuthProvider>();
    final ok = await context
        .read<AIProviderConfigProvider>()
        .selectActiveProvider(uid: auth.user!.uid, providerId: provider.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '"${provider.name}" is now active'
              : 'Could not set active provider',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _test(AIProviderConfig provider) async {
    final providerState = context.read<AIProviderConfigProvider>();
    final apiKey = await providerState.getApiKeyFor(provider);
    if (!mounted) return;
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved API key for this provider. Edit it first.'),
        ),
      );
      return;
    }
    final error = await providerState.testConnection(
      provider: provider,
      apiKey: apiKey,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Connection successful',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchModels(AIProviderConfig provider) async {
    final providerState = context.read<AIProviderConfigProvider>();
    final apiKey = await providerState.getApiKeyFor(provider);
    if (!mounted) return;
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved API key for this provider. Edit it first.'),
        ),
      );
      return;
    }
    final error = await providerState.fetchModels(
      provider: provider,
      apiKey: apiKey,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    if (!mounted) return;
    await context.push(
      RouteNames.modelSelectionPath,
      extra: ModelSelectionArgs(draft: provider, apiKey: apiKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerState = context.watch<AIProviderConfigProvider>();
    final theme = Theme.of(context);

    Widget body;
    if (providerState.loading) {
      body = const AppLoadingIndicator(message: 'Loading providers...');
    } else if (providerState.error != null && providerState.providers.isEmpty) {
      body = AppErrorView(
        message: providerState.error!,
        onRetry: () {
          final uid = context.read<AppAuthProvider>().user?.uid;
          if (uid != null) {
            context.read<AIProviderConfigProvider>().startListening(uid);
          }
        },
      );
    } else if (providerState.providers.isEmpty) {
      body = AppEmptyState(
        icon: Icons.dns_outlined,
        title: 'No AI providers yet',
        message:
            'Add an OpenAI-compatible provider to generate AI replies. '
            'Your API key is stored securely on this device only.',
        actionLabel: 'Add provider',
        onAction: () => context.push(RouteNames.addEditProviderPath),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: providerState.providers.length,
        itemBuilder: (context, index) {
          final provider = providerState.providers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FutureBuilder<String?>(
              future: providerState.getApiKeyFor(provider),
              builder: (context, snapshot) {
                return ProviderCard(
                  provider: provider,
                  isActive: provider.isActive,
                  savedKeyMask: snapshot.hasData
                      ? ApiKeyMasker.mask(snapshot.data)
                      : null,
                  busy: providerState.busy,
                  onEdit: () => context.push(
                    RouteNames.addEditProviderPath,
                    extra: provider,
                  ),
                  onDelete: () => _delete(provider),
                  onActivate: () => _activate(provider),
                  onTest: () => _test(provider),
                  onFetchModels: () => _fetchModels(provider),
                );
              },
            ),
          );
        },
      );
    }

    return Column(
      children: [
        // CORS warning banner for web
        if (kIsWeb)
          Container(
            width: double.infinity,
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Web Limitation: Some AI providers block cross-origin '
                    'requests (CORS). If "Test connection" or "Fetch models" '
                    'fails, the provider must enable CORS for this domain. '
                    'This works on Android without this restriction.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (providerState.error != null && providerState.providers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              providerState.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Expanded(child: body),
        // Quick add provider button at bottom
        if (providerState.providers.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: () => context.push(RouteNames.addEditProviderPath),
                icon: const Icon(Icons.add),
                label: const Text('Add Another Provider'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
