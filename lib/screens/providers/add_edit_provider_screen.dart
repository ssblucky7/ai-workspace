import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/route_names.dart';
import '../../core/routing/app_router.dart' show ModelSelectionArgs;
import '../../core/utils/api_key_masker.dart';
import '../../core/utils/validators.dart';
import '../../models/ai_provider_config.dart';
import '../../providers/ai_provider_config_provider.dart';
import '../../providers/auth_provider.dart';

/// Create or edit an OpenAI-compatible provider configuration: name, base
/// URL, API key (masked when saved), model, organization, temperature,
/// max tokens, and active status. Includes Test connection and Fetch
/// models actions.
class AddEditProviderScreen extends StatefulWidget {
  const AddEditProviderScreen({super.key, this.existing});

  final AIProviderConfig? existing;

  @override
  State<AddEditProviderScreen> createState() => _AddEditProviderScreenState();
}

class _AddEditProviderScreenState extends State<AddEditProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  late final TextEditingController _organizationController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _maxTokensController;

  bool _isActive = false;
  bool _obscureKey = true;
  bool _testing = false;
  bool _fetching = false;
  String? _savedKeyMask;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _baseUrlController = TextEditingController(
      text: existing?.baseUrl ?? 'https://',
    );
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController(
      text: existing?.selectedModel ?? '',
    );
    _organizationController = TextEditingController(
      text: existing?.organizationId ?? '',
    );
    _temperatureController = TextEditingController(
      text: (existing?.temperature ?? AppConstants.defaultTemperature)
          .toStringAsFixed(1),
    );
    _maxTokensController = TextEditingController(
      text: (existing?.maxTokens ?? AppConstants.defaultMaxTokens).toString(),
    );
    _isActive = existing?.isActive ?? false;
    // Look up the real saved key (if any) to show an accurate mask.
    if (existing != null) {
      context.read<AIProviderConfigProvider>().getApiKeyFor(existing).then((
        key,
      ) {
        if (mounted && key != null && key.isNotEmpty) {
          setState(() => _savedKeyMask = ApiKeyMasker.mask(key));
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _organizationController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  AIProviderConfig _buildProvider() {
    final existing = widget.existing;
    final uid = context.read<AppAuthProvider>().user!.uid;
    return AIProviderConfig(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: uid,
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      apiKeyRef: existing?.apiKeyRef,
      selectedModel: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      organizationId: _organizationController.text.trim().isEmpty
          ? null
          : _organizationController.text.trim(),
      temperature:
          double.tryParse(_temperatureController.text) ??
          AppConstants.defaultTemperature,
      maxTokens:
          int.tryParse(_maxTokensController.text) ??
          AppConstants.defaultMaxTokens,
      isActive: _isActive,
      createdAt: existing?.createdAt,
    );
  }

  /// Key used for testing/fetching: the typed key when present, otherwise
  /// the saved key (edit flow).
  Future<String?> _resolveKey() async {
    final typed = _apiKeyController.text.trim();
    if (typed.isNotEmpty) return typed;
    if (widget.existing == null) return null;
    return context.read<AIProviderConfigProvider>().getApiKeyFor(
      widget.existing!,
    );
  }

  Future<void> _testConnection() async {
    if (!_validateBasics()) return;
    final key = await _resolveKey();
    if (!mounted) return;
    if (key == null || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an API key to test.')),
      );
      return;
    }
    setState(() {
      _testing = true;
    });
    final error = await context.read<AIProviderConfigProvider>().testConnection(
      provider: _buildProvider(),
      apiKey: key,
    );
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Connection successful — provider is reachable.'
              : 'Connection failed: $error',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _fetchModels() async {
    if (!_validateBasics()) return;
    final key = await _resolveKey();
    if (!mounted) return;
    if (key == null || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an API key to fetch models.')),
      );
      return;
    }
    setState(() => _fetching = true);
    final error = await context.read<AIProviderConfigProvider>().fetchModels(
      provider: _buildProvider(),
      apiKey: key,
    );
    if (!mounted) return;
    setState(() => _fetching = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fetching models failed: $error')));
      return;
    }
    final models = context.read<AIProviderConfigProvider>().fetchedModels;
    if (models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The provider returned no models.')),
      );
      return;
    }
    // Push model selection screen and wait for result
    final selectedModelId = await context.push<String>(
      '${RouteNames.aiProvidersPath}/model-selection',
      extra: ModelSelectionArgs(draft: _buildProvider(), apiKey: key),
    );
    if (selectedModelId != null && mounted) {
      setState(() {
        _modelController.text = selectedModelId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model selected: $selectedModelId')),
      );
    }
  }

  /// Leaves this screen: pops back to the AI providers list when this page
  /// was pushed onto it, otherwise replaces the stack with the list.
  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.aiProvidersPath);
    }
  }

  bool _validateBasics() {
    final nameError = Validators.validateProviderName(_nameController.text);
    final urlError = Validators.validateBaseUrl(_baseUrlController.text);
    if (nameError != null || urlError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(nameError ?? urlError!)));
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final key = _apiKeyController.text.trim();
    debugPrint('AddEditProviderScreen._save: typed key length=${key.length}, isEmpty=${key.isEmpty}');
    final providerState = context.read<AIProviderConfigProvider>();
    final auth = context.read<AppAuthProvider>();
    final uid = auth.user!.uid;

    final provider = _buildProvider();
    debugPrint('AddEditProviderScreen._save: provider.id=${provider.id}, provider.apiKeyRef=${provider.apiKeyRef}');
    final ok = await providerState.saveProvider(
      uid: uid,
      provider: provider,
      apiKey: key.isEmpty ? null : key,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Provider updated' : 'Provider added'),
          duration: const Duration(seconds: 2),
        ),
      );
      _goBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(providerState.error ?? 'Could not save the provider.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerState = context.watch<AIProviderConfigProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBack),
        title: Text(_isEditing ? 'Edit provider' : 'Add provider'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        color: theme.colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _savedKeyMask != null
                                ? 'A key is already saved for this provider '
                                      '($_savedKeyMask). Leave the field empty '
                                      'to keep it.'
                                : 'No key is saved for this provider yet; '
                                      'enter one below.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Provider name',
                      hintText: 'e.g. My OpenAI-compatible service',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateProviderName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.example.com/v1',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateBaseUrl,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: _isEditing
                          ? 'API key (leave empty to keep saved key)'
                          : 'API key',
                      hintText: _isEditing ? null : 'sk-…',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: _obscureKey ? 'Show key' : 'Hide key',
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                    obscureText: _obscureKey,
                    textInputAction: TextInputAction.next,
                    validator: (value) => _isEditing
                        ? Validators.validateApiKey(value, allowEmpty: true)
                        : Validators.validateApiKey(value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: 'Model ID',
                      hintText: 'gpt-4o-mini or similar',
                      prefixIcon: const Icon(Icons.memory_outlined),
                      suffixIcon: IconButton(
                        tooltip: 'Fetch available models',
                        icon: _fetching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_outlined),
                        onPressed: _fetching ? null : _fetchModels,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      // Optional while editing; the selected model can also
                      // be chosen on the model-selection screen.
                      final model = value?.trim() ?? '';
                      if (model.isEmpty) return null;
                      return Validators.validateModelId(model);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _organizationController,
                    decoration: const InputDecoration(
                      labelText: 'Organization ID (optional)',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: Validators.validateOrganizationId,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _temperatureController,
                          decoration: const InputDecoration(
                            labelText: 'Temperature (0–2)',
                            prefixIcon: Icon(Icons.thermostat_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: Validators.validateTemperature,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxTokensController,
                          decoration: const InputDecoration(
                            labelText: 'Max tokens',
                            prefixIcon: Icon(Icons.data_usage_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          validator: Validators.validateMaxTokens,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    title: const Text('Use this provider for new messages'),
                    subtitle: Text(
                      'Only one provider can be active at a time.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _testing || providerState.busy
                              ? null
                              : _testConnection,
                          icon: _testing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: const Text('Test connection'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: providerState.busy ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isEditing ? 'Save changes' : 'Add provider'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
