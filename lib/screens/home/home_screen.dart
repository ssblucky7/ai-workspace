import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../widgets/conversation_tile.dart';

/// Home: greeting, start-new-chat, searchable recent conversations with
/// rename/delete, theme shortcut, and profile menu.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _startNewChat() async {
    final auth = context.read<AppAuthProvider>();
    final conversations = context.read<ConversationProvider>();
    final id = await conversations.createConversation(
      uid: auth.user!.uid,
      title: AppConstants.defaultConversationTitle,
    );
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conversations.error ?? 'Could not create the conversation.',
          ),
        ),
      );
      return;
    }
    context.push(RouteNames.chatRoutePath(id));
  }

  Future<void> _renameConversation(String conversationId, String title) async {
    final provider = context.read<ConversationProvider>();
    final auth = context.read<AppAuthProvider>();
    final error = await provider.renameConversation(
      uid: auth.user!.uid,
      conversationId: conversationId,
      newTitle: title,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation renamed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteConversation(String conversationId, String title) async {
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
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<ConversationProvider>();
    final auth = context.watch<AppAuthProvider>();

    // Determine which list to show: recent (up to 5) or empty state.
    final recent = conversations.visibleConversations.take(5).toList();
    final showEmptyState = conversations.visibleConversations.isEmpty;

    Widget body;
    if (conversations.loading) {
      body = const AppLoadingIndicator(message: 'Loading conversations...');
    } else if (conversations.error != null) {
      body = AppErrorView(
        message: conversations.error!,
        onRetry: () {
          final uid = auth.user?.uid;
          if (uid != null) {
            context.read<ConversationProvider>().startListening(uid);
          }
        },
      );
    } else if (showEmptyState) {
      body = AppEmptyState(
        icon: Icons.forum_outlined,
        title: 'No conversations yet',
        message: 'Tap "New chat" to start your first conversation.',
        actionLabel: 'New chat',
        onAction: _startNewChat,
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: recent.length + 1, // +1 for the "See all" item
        itemBuilder: (context, index) {
          if (index == recent.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () =>
                    context.push(RouteNames.conversationHistoryPath),
                icon: const Icon(Icons.list_outlined),
                label: const Text('See all conversations'),
              ),
            );
          }
          final conversation = recent[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ConversationTile(
              conversation: conversation,
              onTap: () =>
                  context.push(RouteNames.chatRoutePath(conversation.id)),
              onRename: () => _renameConversation(conversation.id, conversation.title),
              onDelete: () => _deleteConversation(conversation.id, conversation.title),
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
        Expanded(child: body),
      ],
    );
  }
}
