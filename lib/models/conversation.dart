import '../core/utils/date_time_utils.dart';

/// A chat conversation — the main CRUD resource of the assignment.
///
/// Stored at `users/{uid}/conversations/{conversationId}`.
class Conversation {
  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    this.lastMessage = '',
    this.providerId,
    this.modelId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String lastMessage;
  final String? providerId;
  final String? modelId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isNewlyCreated => title == 'New Conversation' && lastMessage.isEmpty;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'lastMessage': lastMessage,
    'providerId': providerId,
    'modelId': modelId,
    'createdAt': createdAt?.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };

  factory Conversation.fromMap(Map<String, dynamic> map, {required String id}) {
    return Conversation(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled',
      lastMessage: map['lastMessage'] as String? ?? '',
      providerId: map['providerId'] as String?,
      modelId: map['modelId'] as String?,
      createdAt: DateTimeUtils.coerce(map['createdAt']),
      updatedAt: DateTimeUtils.coerce(map['updatedAt']),
    );
  }

  Conversation copyWith({
    String? id,
    String? userId,
    String? title,
    String? lastMessage,
    String? providerId,
    String? modelId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Conversation(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    lastMessage: lastMessage ?? this.lastMessage,
    providerId: providerId ?? this.providerId,
    modelId: modelId ?? this.modelId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          other.id == id &&
          other.userId == userId &&
          other.title == title &&
          other.lastMessage == lastMessage &&
          other.providerId == providerId &&
          other.modelId == modelId;

  @override
  int get hashCode =>
      Object.hash(id, userId, title, lastMessage, providerId, modelId);
}
