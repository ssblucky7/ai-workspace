import 'package:flutter/material.dart';

import '../core/utils/date_time_utils.dart';
import '../models/conversation.dart';

/// A conversation list row: title, last-message preview, model indicator,
/// and update timestamp, with rename/delete actions in the overflow menu.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage.isEmpty
                          ? 'No messages yet'
                          : conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (conversation.modelId != null &&
                            conversation.modelId!.isNotEmpty) ...[
                          Icon(
                            Icons.memory_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              conversation.modelId!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          DateTimeUtils.formatTimestamp(conversation.updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onRename != null || onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Conversation actions',
                  itemBuilder: (context) => [
                    if (onRename != null)
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'rename') onRename?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
