import 'package:flutter/material.dart';

import '../core/utils/api_key_masker.dart';
import '../models/ai_provider_config.dart';

/// Card summarizing one AI provider configuration: name, base URL, selected
/// model, active flag, masked key state, and edit/delete/activate actions.
class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key,
    required this.provider,
    required this.isActive,
    this.savedKeyMask,
    this.onEdit,
    this.onDelete,
    this.onActivate,
    this.onTest,
    this.onFetchModels,
    this.busy = false,
  });

  final AIProviderConfig provider;
  final bool isActive;
  final String? savedKeyMask;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onActivate;
  final VoidCallback? onTest;
  final VoidCallback? onFetchModels;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isActive ? Icons.bolt_rounded : Icons.dns_outlined,
                    size: 20,
                    color: isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Active',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        provider.baseUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Provider actions',
                  enabled: !busy,
                  itemBuilder: (context) => [
                    if (onTest != null)
                      const PopupMenuItem(
                        value: 'test',
                        child: Text('Test connection'),
                      ),
                    if (onFetchModels != null)
                      const PopupMenuItem(
                        value: 'models',
                        child: Text('Fetch models'),
                      ),
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'test':
                        onTest?.call();
                      case 'models':
                        onFetchModels?.call();
                      case 'edit':
                        onEdit?.call();
                      case 'delete':
                        onDelete?.call();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(
                  context,
                  Icons.memory_outlined,
                  provider.selectedModel ?? 'No model selected',
                ),
                _chip(
                  context,
                  Icons.key_outlined,
                  savedKeyMask ?? ApiKeyMasker.mask(null),
                ),
                _chip(
                  context,
                  Icons.thermostat_outlined,
                  'Temp ${provider.temperature.toStringAsFixed(1)}',
                ),
                _chip(
                  context,
                  Icons.data_usage_outlined,
                  'Max ${provider.maxTokens} tokens',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isActive && onActivate != null)
                  TextButton.icon(
                    onPressed: busy ? null : onActivate,
                    icon: const Icon(Icons.play_arrow_outlined, size: 18),
                    label: const Text('Set active'),
                  ),
                if (isActive)
                  Text(
                    'Used for new messages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
