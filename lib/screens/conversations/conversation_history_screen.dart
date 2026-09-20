import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/route_names.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../widgets/conversation_tile.dart';
import 'rename_conversation_dialog.dart';

/// Full conversation history: real-time list, search, rename, delete, and
/// navigation into any conversation.
class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({super.key});

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AppAuthProvider>();
      if (!auth.initializing && auth.isSignedIn) {
        context.read<ConversationProvider>().startListening(auth.user!.uid);
      }
    });
  }

  Future<void> _rename(String conversationId, String currentTitle) async {
    final newName = await showRenameConversationDialog(
      context: context,
      initialTitle: currentTitle,
    );
    if (newName == null || !mounted) return;
    final provider = context.read<ConversationProvider>();
    final auth = context.read<AppAuthProvider>();
    final error = await provider.renameConversation(
      uid: auth.user!.uid,
      conversationId: conversationId,
      newTitle: newName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Conversation renamed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _delete(String conversationId, String title) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete conversation?',
      message:
          '"$title" and all its messages will be permanently deleted. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final provider = context.read<ConversationProvider>();
    final auth = context.read<AppAuthProvider>();
    final error = await provider.deleteConversation(
      uid: auth.user!.uid,
      conversationId: conversationId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Conversation deleted'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<ConversationProvider>();
    final theme = Theme.of(context);

    Widget body;
    if (conversations.loading) {
      body = const AppLoadingIndicator(message: 'Loading conversations...');
    } else if (conversations.error != null) {
      body = AppErrorView(
        message: conversations.error!,
        onRetry: () {
          final uid = context.read<AppAuthProvider>().user?.uid;
          if (uid != null) {
            context.read<ConversationProvider>().startListening(uid);
          }
        },
      );
    } else if (conversations.visibleConversations.isEmpty) {
      body = AppEmptyState(
        icon: conversations.hasConversations
            ? Icons.search_off
            : Icons.forum_outlined,
        title: conversations.hasConversations
            ? 'No matching conversations'
            : 'No conversations yet',
        message: conversations.hasConversations
            ? 'Try a different search term.'
            : 'Start a new chat from the home screen.',
        actionLabel: conversations.hasConversations ? null : 'Go to home',
        onAction: conversations.hasConversations
            ? null
            : () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.homePath);
                }
              },
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: conversations.visibleConversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations.visibleConversations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ConversationTile(
              conversation: conversation,
              onTap: () =>
                  context.push(RouteNames.chatRoutePath(conversation.id)),
              onRename: () => _rename(conversation.id, conversation.title),
              onDelete: () => _delete(conversation.id, conversation.title),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: context.read<ConversationProvider>().setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: conversations.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          context.read<ConversationProvider>().clearSearch(),
                    ),
            ),
          ),
        ),
        if (conversations.hasConversations)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${conversations.visibleConversations.length} of '
                '${conversations.conversations.length} conversations',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        Expanded(child: body),
      ],
    );
  }
}
