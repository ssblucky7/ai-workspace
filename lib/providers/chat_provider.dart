import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';
import 'ai_provider_config_provider.dart';

/// Orchestrates the chat flow: Firestore persistence first, then the
/// optional AI request, then assistant-response persistence.
///
/// Design guarantees:
/// - The user's message is ALWAYS saved, even without a configured provider.
/// - A failed AI request persists a failed assistant marker so the failure
///   and its retry button survive navigation and app restarts.
/// - Retries and regenerations update existing messages in place — no
///   duplicate documents.
/// - The loading state is always cleared in a `finally` block.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required this._conversationService,
    required this.aiProviderConfigProvider,
    required this._chatService,
  });

  final ConversationService _conversationService;
  final ChatService _chatService;
  final AIProviderConfigProvider aiProviderConfigProvider;

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  String? _messagesConversationId;
  String? get messagesConversationId => _messagesConversationId;
  String? _openUid;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _loadingMessages = true;
  bool get loadingMessages => _loadingMessages;

  bool _notFound = false;
  bool get notFound => _notFound;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _error;
  String? get error => _error;

  Conversation? _conversation;
  Conversation? get conversation => _conversation;

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Subscribes to the message stream for [conversationId] and loads the
  /// conversation metadata. Re-opening the same conversation is a no-op so
  /// rebuilds never duplicate subscriptions.
  Future<void> openConversation({
    required String uid,
    required String conversationId,
  }) async {
    if (_messagesConversationId == conversationId && _openUid == uid) return;
    await _messagesSub?.cancel();
    _messagesSub = null;
    _messagesConversationId = conversationId;
    _openUid = uid;
    _conversation = null;
    _notFound = false;
    _loadingMessages = true;
    _messages = [];
    notifyListeners();

    try {
      _conversation = await _conversationService.getConversation(
        uid: uid,
        conversationId: conversationId,
      );
      _notFound = _conversation == null;
    } on AppException catch (error) {
      _error = error.message;
      _notFound = true;
    }

    _messagesSub = _conversationService
        .watchMessages(uid: uid, conversationId: conversationId)
        .listen(
          (messages) {
            _messages = messages;
            _loadingMessages = false;
            notifyListeners();
          },
          onError: (Object error) {
            _loadingMessages = false;
            _error = _safeMessage(error);
            notifyListeners();
          },
        );
    notifyListeners();
  }

  /// Sends a user message. Creates the conversation when [conversationId]
  /// is null. Returns the conversation ID used, or null when the input was
  /// empty or a request is already in flight.
  Future<String?> sendMessage({
    required String uid,
    String? conversationId,
    required String content,
  }) async {
    if (_isGenerating) return null;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    _error = null;
    _isGenerating = true;
    notifyListeners();

    String? conversationIdUsed = conversationId;

    try {
      if (conversationIdUsed == null || conversationIdUsed.isEmpty) {
        conversationIdUsed = await _conversationService.createConversation(
          uid: uid,
          title: _conversationService.deriveTitle(trimmed),
        );
        await openConversation(uid: uid, conversationId: conversationIdUsed);
      } else if (_messagesConversationId != conversationIdUsed ||
          _openUid != uid) {
        await openConversation(uid: uid, conversationId: conversationIdUsed);
      }

      // Persist the user message unconditionally.
      final userMessage = await _conversationService.addMessage(
        uid: uid,
        conversationId: conversationIdUsed,
        role: MessageRole.user,
        content: trimmed,
      );

      final provider = aiProviderConfigProvider.activeProvider;
      if (provider == null) {
        _error =
            'No AI provider is configured yet. Open AI Providers from '
            'Settings to connect one — your message has been saved.';
        return conversationIdUsed;
      }

      if (provider.selectedModel == null || provider.selectedModel!.isEmpty) {
        _error =
            'The active provider has no selected model. Choose a model '
            'in AI Providers, then send again.';
        await _saveFailedMarker(
          uid,
          conversationIdUsed,
          'No model selected for the active provider.',
        );
        return conversationIdUsed;
      }

      final apiKey = await aiProviderConfigProvider.getApiKeyFor(provider);
      if (apiKey == null || apiKey.isEmpty) {
        _error =
            'The active provider is missing its saved API key. '
            'Re-enter the key in AI Providers.';
        await _saveFailedMarker(
          uid,
          conversationIdUsed,
          'Missing saved API key.',
        );
        return conversationIdUsed;
      }

      final history = _historyEndingWith(userMessage);
      final reply = await _chatService.sendChat(
        baseUrl: provider.baseUrl,
        apiKey: apiKey,
        model: provider.selectedModel!,
        messages: history,
        temperature: provider.temperature,
        maxTokens: provider.maxTokens,
        organizationId: provider.organizationId,
      );

      await _conversationService.addMessage(
        uid: uid,
        conversationId: conversationIdUsed,
        role: MessageRole.assistant,
        content: reply,
      );
      return conversationIdUsed;
    } on AppException catch (error) {
      _error = error.message;
      await _saveFailedMarker(uid, conversationIdUsed, error.message);
      return conversationIdUsed;
    } catch (error) {
      final message = _safeMessage(error);
      _error = message;
      await _saveFailedMarker(uid, conversationIdUsed, message);
      return conversationIdUsed;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Retries a failed assistant marker: re-requests the reply and resolves
  /// the same message document in place (no duplicates).
  Future<String?> retryFailedMessage({
    required String uid,
    required String messageId,
  }) async {
    final conversationId = _messagesConversationId;
    if (_isGenerating || conversationId == null) return null;

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return null;
    final failed = _messages[index];
    if (!failed.isFailed) return null;

    return _resolveAssistantTurn(
      uid: uid,
      conversationId: conversationId,
      target: failed,
      history: _sliceFromEnd(_messages.sublist(0, index)),
    );
  }

  /// Regenerates the most recent successful assistant reply from its
  /// preceding user turn.
  Future<String?> regenerateResponse({required String uid}) async {
    final conversationId = _messagesConversationId;
    if (_isGenerating || conversationId == null) return null;

    var assistantIndex = -1;
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.assistant) {
        assistantIndex = i;
        break;
      }
    }
    if (assistantIndex < 0) return null;
    final target = _messages[assistantIndex];

    return _resolveAssistantTurn(
      uid: uid,
      conversationId: conversationId,
      target: target,
      history: _sliceFromEnd(_messages.sublist(0, assistantIndex)),
    );
  }

  Future<String?> _resolveAssistantTurn({
    required String uid,
    required String conversationId,
    required ChatMessage target,
    required List<ChatMessage> history,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      final provider = aiProviderConfigProvider.activeProvider;
      final apiKey = provider == null
          ? null
          : await aiProviderConfigProvider.getApiKeyFor(provider);
      if (provider == null ||
          apiKey == null ||
          apiKey.isEmpty ||
          provider.selectedModel == null ||
          provider.selectedModel!.isEmpty) {
        _error =
            'The AI provider is not fully configured. '
            'Check AI Providers and try again.';
        return null;
      }

      final reply = await _chatService.sendChat(
        baseUrl: provider.baseUrl,
        apiKey: apiKey,
        model: provider.selectedModel!,
        messages: history,
        temperature: provider.temperature,
        maxTokens: provider.maxTokens,
        organizationId: provider.organizationId,
      );

      await _conversationService.resolveMessage(
        uid: uid,
        conversationId: conversationId,
        messageId: target.id,
        content: reply,
        status: MessageStatus.sent,
      );
      await _conversationService.updatePreview(
        uid: uid,
        conversationId: conversationId,
        lastMessage: _conversationService.previewOf(reply),
      );
      return conversationId;
    } on AppException catch (error) {
      _error = error.message;
      if (target.isFailed) {
        // Keep the failed marker's error text up to date.
        await _conversationService.updateMessageStatus(
          uid: uid,
          conversationId: conversationId,
          messageId: target.id,
          status: MessageStatus.failed,
          errorMessage: error.message,
        );
      }
      return null;
    } catch (error) {
      _error = _safeMessage(error);
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Deletes every message in the open conversation (confirmation handled
  /// by the UI). Returns null on success or a user-safe error message.
  Future<String?> clearChat({required String uid}) async {
    final conversationId = _messagesConversationId;
    if (conversationId == null) return null;
    try {
      await _conversationService.clearMessages(
        uid: uid,
        conversationId: conversationId,
      );
      return null;
    } on AppException catch (error) {
      return error.message;
    } catch (error) {
      return _safeMessage(error);
    }
  }

  /// Clears all state — called on sign-out so no user data leaks into the
  /// next session and no subscription outlives the user.
  void clearState() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _messagesConversationId = null;
    _openUid = null;
    _messages = [];
    _loadingMessages = true;
    _notFound = false;
    _conversation = null;
    _isGenerating = false;
    _error = null;
    notifyListeners();
  }

  /// History for the request, ending with [userMessage] exactly once even
  /// if the stream has not delivered it yet.
  List<ChatMessage> _historyEndingWith(ChatMessage userMessage) {
    final existing = _messages.where((m) => m.id != userMessage.id).toList();
    return _sliceFromEnd([...existing, userMessage]);
  }

  List<ChatMessage> _sliceFromEnd(List<ChatMessage> list) =>
      list.length <= AppConstants.aiHistoryMessageLimit
      ? list
      : list.sublist(list.length - AppConstants.aiHistoryMessageLimit);

  Future<void> _saveFailedMarker(
    String uid,
    String? conversationId,
    String errorMessage,
  ) async {
    if (conversationId == null || conversationId.isEmpty) return;
    try {
      await _conversationService.addMessage(
        uid: uid,
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: '',
        status: MessageStatus.failed,
        errorMessage: errorMessage,
        // Keep the user's text as the conversation preview.
        previewText: _messages.lastOrNull?.isUser == true
            ? _messages.last.content
            : null,
      );
    } catch (_) {
      // The marker is best-effort; the local error state still surfaces.
    }
  }

  String _safeMessage(Object error) {
    if (error is AppException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }
}
