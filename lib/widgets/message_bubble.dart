import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/date_time_utils.dart';
import '../models/chat_message.dart';
import '../theme/chat_theme_extension.dart';
import '../widgets/markdown_content.dart';

/// One chat bubble with role styling, timestamp, and per-message actions
/// (copy; retry for failed assistant markers; regenerate on the last
/// assistant reply).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.isLastAssistant = false,
    this.onRegenerate,
  });

  final ChatMessage message;
  final VoidCallback? onRetry;
  final bool isLastAssistant;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = chatTheme(context);
    final isUser = message.isUser;
    final isFailed = message.isFailed;

    final bubbleColor = isFailed
        ? chat.failedBubble
        : isUser
        ? chat.userBubble
        : chat.assistantBubble;
    final textColor = isFailed
        ? chat.failedBubbleText
        : isUser
        ? chat.userBubbleText
        : chat.assistantBubbleText;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isFailed && (message.content.isEmpty))
                          Text(
                            'This response could not be generated.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (!isUser)
                          MarkdownContent(
                            content: message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              height: 1.4,
                            ),
                          )
                        else
                          SelectableText(
                            message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        if (isFailed && message.errorMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            message.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          DateTimeUtils.formatTimestamp(message.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ],
            ),
            if (!isUser || isFailed) const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.content.isNotEmpty)
                  Tooltip(
                    message: 'Copy message',
                    child: IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message copied'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                if (isFailed && onRetry != null)
                  Tooltip(
                    message: 'Retry this response',
                    child: IconButton(
                      icon: const Icon(Icons.refresh, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: onRetry,
                    ),
                  ),
                if (isLastAssistant && onRegenerate != null)
                  Tooltip(
                    message: 'Regenerate response',
                    child: IconButton(
                      icon: const Icon(Icons.restart_alt_outlined, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: onRegenerate,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
