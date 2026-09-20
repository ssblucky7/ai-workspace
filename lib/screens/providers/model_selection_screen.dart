import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/route_names.dart';
import '../../models/ai_provider_config.dart';
import '../../providers/ai_provider_config_provider.dart';

/// Searchable list of models fetched from the provider. Selecting a model
/// writes it back to the provider configuration being edited.
///
/// Pushed on top of the add/edit flow, so selection returns to that screen.
class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({
    super.key,
    required this.draft,
    required this.apiKey,
  });

  final AIProviderConfig draft;
  final String apiKey;

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final models = context.watch<AIProviderConfigProvider>().fetchedModels;
    final filtered = _query.isEmpty
        ? models
        : models
              .where((m) => m.id.toLowerCase().contains(_query.toLowerCase()))
              .toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          // Pop back to whatever pushed this screen (the add/edit form or
          // the providers list) instead of resetting the stack with go().
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.addEditProviderPath);
            }
          },
        ),
        title: const Text('Select a model'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search models…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          if (widget.draft.selectedModel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Current: ${widget.draft.selectedModel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Expanded(
            child: models.isEmpty
                ? Center(
                    child: Text(
                      'No models were fetched yet. Go back and tap the '
                      'fetch button next to the model field.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      'No models match "$_query".',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final model = filtered[index];
                      final isSelected = model.id == widget.draft.selectedModel;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            leading: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.memory_outlined,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              model.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: model.ownedBy != null
                                ? Text(
                                    'Owned by ${model.ownedBy}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () {
                              // Return the chosen model to the
                              // add/edit screen via Navigator.pop with the model ID.
                              Navigator.of(context).pop(model.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
