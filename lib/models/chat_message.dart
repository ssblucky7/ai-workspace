import '../core/utils/date_time_utils.dart';

/// Who authored a chat message.
enum MessageRole { user, assistant, system }

/// Lifecycle state of a message while it is being sent or after a failure.
enum MessageStatus { sending, sent, failed }

/// A single message inside a conversation.
///
/// Stored at
/// `users/{uid}/conversations/{conversationId}/messages/{messageId}`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.createdAt,
    this.status = MessageStatus.sent,
    this.errorMessage,
  });

  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime? createdAt;
  final MessageStatus status;
  final String? errorMessage;

  bool get isUser => role == MessageRole.user;
  bool get isFailed => status == MessageStatus.failed;

  /// Serialization with enum names as stable strings. `fromMap` tolerates
  /// unknown or missing enum values by falling back to safe defaults instead
  /// of throwing, so one malformed document cannot break the whole stream.
  Map<String, dynamic> toMap() => {
    'id': id,
    'conversationId': conversationId,
    'role': role.name,
    'content': content,
    'createdAt': createdAt?.millisecondsSinceEpoch,
    'status': status.name,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map, {required String id}) {
    return ChatMessage(
      id: id,
      conversationId: map['conversationId'] as String? ?? '',
      role:
          MessageRole.values.where((r) => r.name == map['role']).firstOrNull ??
          MessageRole.system,
      content: map['content'] as String? ?? '',
      createdAt: DateTimeUtils.coerce(map['createdAt']),
      status:
          MessageStatus.values
              .where((s) => s.name == map['status'])
              .firstOrNull ??
          MessageStatus.sent,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    String? errorMessage,
  }) => ChatMessage(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          other.id == id &&
          other.conversationId == conversationId &&
          other.role == role &&
          other.content == content &&
          other.status == status &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode =>
      Object.hash(id, conversationId, role, content, status, errorMessage);
}
