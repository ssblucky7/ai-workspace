import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/route_names.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../models/ai_provider_config.dart';
import '../../models/chat_message.dart';
import '../../providers/ai_provider_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_composer.dart';
import '../conversations/rename_conversation_dialog.dart';

/// Chat screen: real-time message stream, message composer, retry /
/// regenerate, rename, delete, clear-chat, and helpful empty-state
/// suggestions. Wide layouts show the conversation history beside the chat.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.conversationId});

  final String? conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AppAuthProvider>();
      if (!auth.initializing && auth.isSignedIn) {
        final chat = context.read<ChatProvider>();
        if (widget.conversationId != null) {
          chat.openConversation(
            uid: auth.user!.uid,
            conversationId: widget.conversationId!,
          );
        } else {
          chat.clearState();
        }
      }
    });
    // Auto-scroll when new messages are added
    _scrollController.addListener(_onScroll);
    
    // Auto-scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
    
    // Watch for new messages and auto-scroll
    final chat = context.read<ChatProvider>();
    chat.addListener(_onMessagesChanged);
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final auth = context.read<AppAuthProvider>();
        if (auth.initializing || !auth.isSignedIn) return;
        final chat = context.read<ChatProvider>();
        if (widget.conversationId != null) {
          chat.openConversation(
            uid: auth.user!.uid,
            conversationId: widget.conversationId!,
          );
        } else {
          chat.clearState();
        }
      });
    }
    // Auto-scroll to bottom when conversation changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    final chat = context.read<ChatProvider>();
    chat.removeListener(_onMessagesChanged);
    super.dispose();
  }

  void _onMessagesChanged() {
    // Auto-scroll to bottom when new messages are added
    if (mounted && _scrollController.hasClients) {
      _scrollToBottom();
    }
  }

  void _onScroll() {
    // Auto-scroll to bottom when new messages are added
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      // User is near bottom, keep auto-scrolling
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  /// Updates the provider's selected model in Firestore.
  Future<void> _updateProviderModel(
    AIProviderConfig provider,
    String newModelId,
    String apiKey,
  ) async {
    final updatedProvider = provider.copyWith(
      selectedModel: newModelId,
      isActive: true,
    );
    await context.read<AIProviderConfigProvider>().saveProvider(
      uid: provider.userId,
      provider: updatedProvider,
      apiKey: apiKey,
    );
  }

  /// Shows a dialog to select the active provider.
  Future<void> _showProviderSelector(
    BuildContext context,
    AIProviderConfigProvider providerState,
  ) async {
    final providers = providerState.providers;
    if (providers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No providers configured. Add one first.')),
      );
      return;
    }

    final activeProvider = providerState.activeProvider;
    final auth = context.read<AppAuthProvider>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Active Provider'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: activeProvider?.id,
            onChanged: (value) async {
              if (value != null && auth.user != null) {
                Navigator.of(dialogContext).pop();
                final ok = await providerState.selectActiveProvider(
                  uid: auth.user!.uid,
                  providerId: value,
                );
                if (!mounted) return;
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Active provider changed to ${providers.firstWhere((p) => p.id == value).name}'
                          : 'Failed to switch provider',
                    ),
                  ),
                );
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final p = providers[index];
                final isActive = activeProvider?.id == p.id;
                return RadioListTile<String>(
                  value: p.id,
                  title: Text(p.name),
                  subtitle: Text('${p.baseUrl} \u2022 ${p.selectedModel ?? 'No model'}'),
                  secondary: isActive
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to select the model for the active provider.
  Future<void> _showModelSelector(
    BuildContext context,
    AIProviderConfigProvider providerState,
  ) async {
    final activeProvider = providerState.activeProvider;
    if (activeProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active provider. Select a provider first.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final apiKey = await providerState.getApiKeyFor(activeProvider);
    if (apiKey == null || apiKey.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No API key saved for the active provider.'),
        ),
      );
      return;
    }

    // Fetch models if not already fetched
    if (providerState.fetchedModels.isEmpty) {
      final error = await providerState.fetchModels(
        provider: activeProvider,
        apiKey: apiKey,
      );
      if (!mounted) return;
      if (error != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to fetch models: $error')),
        );
        return;
      }
    }

    final models = providerState.fetchedModels;
    if (models.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No models available for this provider.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Select Model for ${activeProvider.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: activeProvider.selectedModel,
            onChanged: (value) async {
              if (value != null) {
                Navigator.of(dialogContext).pop();
                await _updateProviderModel(activeProvider, value, apiKey);
                if (!mounted) return;
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Model changed to $value')),
                );
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: models.length,
              itemBuilder: (context, index) {
                final model = models[index];
                final isSelected = activeProvider.selectedModel == model.id;
                return RadioListTile<String>(
                  value: model.id,
                  title: Text(model.id),
                  subtitle: model.ownedBy != null
                      ? Text('Owned by ${model.ownedBy}')
                      : null,
                  secondary: isSelected
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Navigates to the add/edit provider screen.
  Future<void> _configureNewProvider(BuildContext context) async {
    await context.push(RouteNames.addEditProviderPath);
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    final auth = context.read<AppAuthProvider>();
    if (auth.user != null && mounted) {
      // ignore: use_build_context_synchronously
      context.read<AIProviderConfigProvider>().startListening(auth.user!.uid);
    }
  }

  Future<void> _sendMessage(String text) async {
    final auth = context.read<AppAuthProvider>();
    final chat = context.read<ChatProvider>();
    final usedId = await chat.sendMessage(
      uid: auth.user!.uid,
      conversationId: widget.conversationId,
      content: text,
    );
    _scrollToBottom();
    if (!mounted) return;
    if (chat.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chat.error!),
          duration: const Duration(seconds: 4),
          action: chat.error!.contains('provider')
              ? SnackBarAction(
                  label: 'Configure',
                  onPressed: () => context.push(RouteNames.aiProvidersPath),
                )
              : null,
        ),
      );
    }
    if (usedId != null && widget.conversationId == null) {
      final currentPath = GoRouterState.of(context).matchedLocation;
      if (currentPath != RouteNames.chatRoutePath(usedId)) {
        // Replace (not push) so the transient /chat/new page does not
        // stay in the back stack; back then returns to the caller.
        context.replace(RouteNames.chatRoutePath(usedId));
      }
    }
  }

  Future<void> _retry(String failedMessageId) async {
    final auth = context.read<AppAuthProvider>();
    final chat = context.read<ChatProvider>();
    final conversationId = chat.messagesConversationId;
    if (conversationId == null) return;
    await chat.retryFailedMessage(
      uid: auth.user!.uid,
      messageId: failedMessageId,
    );
    _scrollToBottom();
  }

  Future<void> _regenerate() async {
    final auth = context.read<AppAuthProvider>();
    final chat = context.read<ChatProvider>();
    final conversationId = chat.messagesConversationId;
    if (conversationId == null) return;
    await chat.regenerateResponse(uid: auth.user!.uid);
    _scrollToBottom();
  }

  Future<void> _rename() async {
    final chat = context.read<ChatProvider>();
    final conversation = chat.conversation;
    if (conversation == null) return;
    final newTitle = await showRenameConversationDialog(
      context: context,
      initialTitle: conversation.title,
    );
    if (newTitle == null || !mounted) return;
    final auth = context.read<AppAuthProvider>();
    final error = await context.read<ConversationProvider>().renameConversation(
      uid: auth.user!.uid,
      conversationId: conversation.id,
      newTitle: newTitle,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Clear conversation?',
      message:
          'All messages will be deleted. The conversation itself remains.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final chat = context.read<ChatProvider>();
    final auth = context.read<AppAuthProvider>();
    final error = await chat.clearChat(uid: auth.user!.uid);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _deleteConversation() async {
    final chat = context.read<ChatProvider>();
    final conversation = chat.conversation;
    if (conversation == null) return;
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete conversation?',
      message:
          '"${conversation.title}" and all its messages will be permanently deleted. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final auth = context.read<AppAuthProvider>();
    final error = await context.read<ConversationProvider>().deleteConversation(
      uid: auth.user!.uid,
      conversationId: conversation.id,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      context.go(RouteNames.homePath);
    }
  }

  String? _lastAssistantId(List<ChatMessage> messages) {
    for (final m in messages.reversed) {
      if (m.role == MessageRole.assistant) return m.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final conversation = chat.conversation;
    final theme = Theme.of(context);
    final activeProvider = context.watch<AIProviderConfigProvider>().activeProvider;

    final title = conversation?.title ?? 'New Conversation';
    final subtitle = activeProvider != null
        ? '${activeProvider.name} \u2022 ${activeProvider.selectedModel ?? 'No model'}'
        : 'No provider configured \u2014 tap to add one';

    final messageList = chat.loadingMessages
        ? const AppLoadingIndicator(message: 'Loading messages...')
        : chat.notFound
            ? AppEmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'Conversation not found',
                message: 'It may have been deleted.',
                actionLabel: 'Go to home',
                onAction: () => context.go(RouteNames.homePath),
              )
            : chat.messages.isEmpty
                ? AppEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'Start the conversation',
                    message: 'Type a message below to begin.',
                    actionLabel: 'New chat',
                    onAction: () => context.push(RouteNames.newChatPath),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final lastAssistantId = _lastAssistantId(chat.messages);
                      final message = chat.messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: MessageBubble(
                          message: message,
                          isLastAssistant: message.id == lastAssistantId,
                          onRegenerate: _regenerate,
                          onRetry: () => _retry(message.id),
                        ),
                      );
                    },
                  );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Switch provider or model',
            icon: const Icon(Icons.dns_outlined),
            onSelected: (value) async {
              final providerState = context.read<AIProviderConfigProvider>();
              if (value == 'select_provider') {
                await _showProviderSelector(context, providerState);
              } else if (value == 'select_model') {
                await _showModelSelector(context, providerState);
              } else if (value == 'configure_provider') {
                await _configureNewProvider(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select_provider',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Switch Provider'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'select_model',
                child: ListTile(
                  leading: Icon(Icons.memory_outlined),
                  title: Text('Switch Model'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'configure_provider',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add / Configure Provider'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          if (conversation != null)
            IconButton(
              tooltip: 'Rename conversation',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _rename,
            ),
          IconButton(
            tooltip: 'Clear messages',
            icon: const Icon(Icons.clear_all_outlined),
            onPressed: chat.messages.isEmpty ? null : _clearChat,
          ),
          if (conversation != null)
            IconButton(
              tooltip: 'Delete conversation',
              icon: const Icon(Icons.delete_outlined),
              onPressed: _deleteConversation,
            ),
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go(RouteNames.homePath),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chat.error != null && !chat.isGenerating)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chat.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dismiss',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => context.read<ChatProvider>().clearError(),
                  ),
                ],
              ),
            ),
          Expanded(child: messageList),
          if (chat.isGenerating || chat.messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Messages sync with Firestore in real time.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          MessageComposer(onSend: _sendMessage, isSending: chat.isGenerating),
        ],
      ),
    );
  }
}
