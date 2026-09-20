import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';

/// State for the user's conversation list: real-time stream subscription,
/// search filtering, CRUD orchestration, and per-action feedback.
class ConversationProvider extends ChangeNotifier {
  ConversationProvider({required this._service});

  final ConversationService _service;

  StreamSubscription<List<Conversation>>? _conversationsSub;
  String? _subscribedUid;

  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;

  /// Conversations filtered by the current search query (title, last
  /// message, model; case-insensitive).
  List<Conversation> get visibleConversations {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _conversations;
    return _conversations.where((c) {
      return c.title.toLowerCase().contains(query) ||
          c.lastMessage.toLowerCase().contains(query) ||
          (c.modelId ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Conversation? _selectedConversation;
  Conversation? get selectedConversation => _selectedConversation;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool get hasConversations => _conversations.isNotEmpty;

  /// Attaches (or re-attaches after auth change / retry) the real-time
  /// conversation stream for [uid]. The old subscription is always
  /// cancelled first, preventing duplicates and cross-user leaks.
  void startListening(String uid) {
    if (_subscribedUid == uid) return;
    _subscribedUid = uid;
    _conversationsSub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();
    _conversationsSub = _service
        .watchConversations(uid: uid)
        .listen(
          (conversations) {
            _conversations = conversations;
            _loading = false;
            _error = null;
            // Keep the selected conversation fresh when it updates in place.
            if (_selectedConversation != null) {
              _selectedConversation = _conversations.firstWhere(
                (c) => c.id == _selectedConversation!.id,
                orElse: () => _selectedConversation!,
              );
            }
            notifyListeners();
          },
          onError: (Object error) {
            _loading = false;
            _error = _safeMessage(error);
            notifyListeners();
          },
        );
  }

  /// Clears all user-scoped state — called on sign-out so the next user
  /// starts clean and no stale subscription leaks.
  void clear() {
    _conversationsSub?.cancel();
    _conversationsSub = null;
    _subscribedUid = null;
    _conversations = [];
    _selectedConversation = null;
    _searchQuery = '';
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }

  void selectConversation(Conversation? conversation) {
    _selectedConversation = conversation;
    notifyListeners();
  }

  Conversation? conversationById(String id) =>
      _conversations.where((c) => c.id == id).firstOrNull;

  /// Creates a conversation. [onCreated] receives the new conversation ID
  /// so the caller can navigate to its chat screen.
  Future<String?> createConversation({
    required String uid,
    String? title,
    String? providerId,
    String? modelId,
  }) async {
    try {
      final id = await _service.createConversation(
        uid: uid,
        title: title,
        providerId: providerId,
        modelId: modelId,
      );
      return id;
    } on AppException catch (error) {
      _error = error.message;
      notifyListeners();
      return null;
    } catch (error) {
      _error = _safeMessage(error);
      notifyListeners();
      return null;
    }
  }

  /// Renames a conversation after validation. Returns an error message or
  /// null on success.
  Future<String?> renameConversation({
    required String uid,
    required String conversationId,
    required String newTitle,
  }) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return 'Title cannot be empty.';
    try {
      await _service.renameConversation(
        uid: uid,
        conversationId: conversationId,
        newTitle: trimmed,
      );
      return null;
      // Stream updates the list automatically; no manual refresh needed.
    } on AppException catch (error) {
      return error.message;
    } catch (error) {
      return _safeMessage(error);
    }
  }

  /// Deletes a conversation and its messages after confirmation elsewhere.
  Future<String?> deleteConversation({
    required String uid,
    required String conversationId,
  }) async {
    try {
      await _service.deleteConversation(
        uid: uid,
        conversationId: conversationId,
      );
      if (_selectedConversation?.id == conversationId) {
        _selectedConversation = null;
      }
      return null;
    } on AppException catch (error) {
      return error.message;
    } catch (error) {
      return _safeMessage(error);
    }
  }

  String _safeMessage(Object error) {
    if (error is AppException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    super.dispose();
  }
}
