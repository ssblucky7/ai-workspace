import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

/// Firestore data-access layer for conversations and their messages.
///
/// Every method takes the authenticated user's [uid] and scopes all paths
/// under `users/{uid}/...`, so operations can never touch another user's
/// data. SDK errors are converted into typed, user-safe [AppException]s.
class ConversationService {
  ConversationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Real-time conversation list ordered by most recently updated.
  Stream<List<Conversation>> watchConversations({required String uid}) {
    return _firestore
        .collection(FirestorePaths.conversationsCol(uid))
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: false)
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Conversation.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Real-time messages for one conversation, oldest first.
  Stream<List<ChatMessage>> watchMessages({
    required String uid,
    required String conversationId,
  }) {
    return _firestore
        .collection(FirestorePaths.messagesCol(uid, conversationId))
        .orderBy('createdAt', descending: false)
        .snapshots(includeMetadataChanges: false)
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Fetches a single conversation; returns `null` when it does not exist.
  Future<Conversation?> getConversation({
    required String uid,
    required String conversationId,
  }) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.conversationDoc(uid, conversationId))
          .get();
      if (!snapshot.exists) return null;
      return Conversation.fromMap(snapshot.data()!, id: snapshot.id);
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Creates a conversation owned by [uid]; returns the new document ID.
  Future<String> createConversation({
    required String uid,
    String? title,
    String? providerId,
    String? modelId,
  }) async {
    try {
      final docRef = await _firestore
          .collection(FirestorePaths.conversationsCol(uid))
          .add({
            'userId': uid,
            'title': title ?? AppConstants.defaultConversationTitle,
            'lastMessage': '',
            'providerId': providerId,
            'modelId': modelId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Saves a message under the conversation and refreshes the parent's
  /// lastMessage/updatedAt. [previewText] overrides the conversation-list
  /// preview (used when the user message must remain the preview while the
  /// assistant turn failed).
  Future<ChatMessage> addMessage({
    required String uid,
    required String conversationId,
    required MessageRole role,
    required String content,
    MessageStatus status = MessageStatus.sent,
    String? errorMessage,
    String? previewText,
  }) async {
    final messageRef = _firestore
        .collection(FirestorePaths.messagesCol(uid, conversationId))
        .doc();
    try {
      await messageRef.set({
        'id': messageRef.id,
        'conversationId': conversationId,
        'role': role.name,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'status': status.name,
        'errorMessage': ?errorMessage,
      });
      final preview = previewText ?? previewOf(content);
      await _touchConversation(
        uid: uid,
        conversationId: conversationId,
        lastMessage: preview,
      );
      return ChatMessage(
        id: messageRef.id,
        conversationId: conversationId,
        role: role,
        content: content,
        createdAt: DateTime.now(),
        status: status,
        errorMessage: errorMessage,
      );
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Truncates message content for the conversation-list preview field.
  String previewOf(String content) {
    if (content.length <= AppConstants.lastMessagePreviewLength) {
      return content;
    }
    return '${content.substring(0, AppConstants.lastMessagePreviewLength)}…';
  }

  /// Updates a message's status (e.g. sending -> sent/failed).
  Future<void> updateMessageStatus({
    required String uid,
    required String conversationId,
    required String messageId,
    required MessageStatus status,
    String? errorMessage,
  }) async {
    try {
      await _firestore
          .collection(FirestorePaths.messagesCol(uid, conversationId))
          .doc(messageId)
          .update({'status': status.name, 'errorMessage': ?errorMessage});
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Resolves a failed/regenerating assistant message in place: replaces
  /// content, clears the error, and marks it sent. Used by retry and
  /// regenerate so no duplicate documents are created.
  Future<void> resolveMessage({
    required String uid,
    required String conversationId,
    required String messageId,
    required String content,
    required MessageStatus status,
  }) async {
    try {
      await _firestore
          .collection(FirestorePaths.messagesCol(uid, conversationId))
          .doc(messageId)
          .update({
            'content': content,
            'status': status.name,
            'errorMessage': FieldValue.delete(),
          });
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Updates only the conversation preview fields (lastMessage/updatedAt).
  Future<void> updatePreview({
    required String uid,
    required String conversationId,
    required String lastMessage,
  }) async {
    try {
      await _firestore
          .doc(FirestorePaths.conversationDoc(uid, conversationId))
          .update({
            'lastMessage': lastMessage,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Updates the content of a user message (edit / regenerate support).
  Future<void> updateMessageContent({
    required String uid,
    required String conversationId,
    required String messageId,
    required String content,
  }) async {
    try {
      await _firestore
          .collection(FirestorePaths.messagesCol(uid, conversationId))
          .doc(messageId)
          .update({'content': content});
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Renames a conversation and bumps updatedAt.
  Future<void> renameConversation({
    required String uid,
    required String conversationId,
    required String newTitle,
  }) async {
    try {
      await _firestore
          .doc(FirestorePaths.conversationDoc(uid, conversationId))
          .update({
            'title': newTitle,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Updates provider/model metadata and updatedAt (no lastMessage change).
  Future<void> updateConversationMetadata({
    required String uid,
    required String conversationId,
    String? providerId,
    String? modelId,
    String? title,
  }) async {
    try {
      await _firestore
          .doc(FirestorePaths.conversationDoc(uid, conversationId))
          .update({
            'providerId': ?providerId,
            'modelId': ?modelId,
            'title': ?title,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Deletes all messages in the conversation but keeps the conversation.
  Future<void> clearMessages({
    required String uid,
    required String conversationId,
  }) async {
    try {
      await _deleteCollectionPaginated(
        _firestore.collection(FirestorePaths.messagesCol(uid, conversationId)),
      );
      await _firestore
          .doc(FirestorePaths.conversationDoc(uid, conversationId))
          .update({
            'lastMessage': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Deletes a conversation together with its messages.
  ///
  /// Firestore does NOT cascade-delete subcollections, so messages are
  /// removed client-side in paginated batches (each below the 500-op write
  /// limit) before the parent document is deleted. For very large
  /// conversations a trusted backend/Cloud Function would be preferable —
  /// see README.md ("Known limitations").
  Future<void> deleteConversation({
    required String uid,
    required String conversationId,
  }) async {
    try {
      await _deleteCollectionPaginated(
        _firestore.collection(FirestorePaths.messagesCol(uid, conversationId)),
      );
      await _firestore
          .doc(FirestorePaths.conversationDoc(uid, conversationId))
          .delete();
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Repeatedly fetches a batch of document IDs and deletes them until the
  /// collection is empty. Batch size stays under Firestore's 500-operation
  /// limit per commit.
  Future<void> _deleteCollectionPaginated(CollectionReference ref) async {
    while (true) {
      final snapshot = await ref
          .limit(AppConstants.firestoreDeleteBatchSize)
          .get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Updates lastMessage and updatedAt on the parent conversation.
  Future<void> _touchConversation({
    required String uid,
    required String conversationId,
    required String lastMessage,
  }) async {
    await _firestore
        .doc(FirestorePaths.conversationDoc(uid, conversationId))
        .update({
          'lastMessage': lastMessage,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Derives a short conversation title from the first user message.
  String deriveTitle(String firstMessage) {
    final trimmed = firstMessage.trim();
    if (trimmed.isEmpty) return AppConstants.defaultConversationTitle;
    if (trimmed.length <= AppConstants.derivedTitleMaxLength) return trimmed;
    return '${trimmed.substring(0, AppConstants.derivedTitleMaxLength).trimRight()}…';
  }
}
