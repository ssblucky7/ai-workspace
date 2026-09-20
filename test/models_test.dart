import 'package:flutter_test/flutter_test.dart';

import 'package:ai_workspace/models/app_user.dart';
import 'package:ai_workspace/models/chat_message.dart';
import 'package:ai_workspace/models/conversation.dart';

void main() {
  group('AppUser serialization', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    const user = AppUser(
      uid: 'uid-1',
      fullName: 'Ada Lovelace',
      email: 'ada@example.com',
      photoUrl: null,
    );

    test('round-trips through toMap/fromMap with timestamps', () {
      final withTimes = user.copyWith(createdAt: now, updatedAt: now);
      final restored = AppUser.fromMap(withTimes.toMap());
      expect(restored.uid, 'uid-1');
      expect(restored.fullName, 'Ada Lovelace');
      expect(restored.email, 'ada@example.com');
      expect(restored.createdAt, now);
      expect(restored.updatedAt, now);
    });

    test('fromMap tolerates missing or malformed fields', () {
      final restored = AppUser.fromMap({});
      expect(restored.uid, '');
      expect(restored.fullName, '');
      expect(restored.createdAt, isNull);
    });

    test('initials derive correctly', () {
      expect(user.initials, 'AL');
      expect(user.copyWith(fullName: 'Cher').initials, 'CH');
      expect(user.copyWith(fullName: 'X').initials, 'X');
    });
  });

  group('Conversation serialization', () {
    final created = DateTime.fromMillisecondsSinceEpoch(1690000000000);
    final updated = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final conversation = Conversation(
      id: 'c1',
      userId: 'uid-1',
      title: 'Project ideas',
      lastMessage: 'Tell me more',
      providerId: 'p1',
      modelId: 'gpt-test',
      createdAt: created,
      updatedAt: updated,
    );

    test('round-trips through toMap/fromMap', () {
      final restored = Conversation.fromMap(
        conversation.toMap(),
        id: conversation.id,
      );
      expect(restored.title, 'Project ideas');
      expect(restored.lastMessage, 'Tell me more');
      expect(restored.providerId, 'p1');
      expect(restored.modelId, 'gpt-test');
      expect(restored.createdAt, created);
      expect(restored.updatedAt, updated);
    });

    test('fromMap falls back to safe defaults', () {
      final restored = Conversation.fromMap({}, id: 'x');
      expect(restored.userId, '');
      expect(restored.title, 'Untitled');
      expect(restored.lastMessage, '');
    });

    test('copyWith updates only the given fields', () {
      final renamed = conversation.copyWith(title: 'Renamed');
      expect(renamed.title, 'Renamed');
      expect(renamed.lastMessage, conversation.lastMessage);
      expect(renamed.id, conversation.id);
    });
  });

  group('ChatMessage serialization', () {
    test('round-trips roles and statuses by name', () {
      final message = ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: MessageRole.user,
        content: 'Hello',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        status: MessageStatus.sent,
      );
      final restored = ChatMessage.fromMap(message.toMap(), id: 'm1');
      expect(restored.role, MessageRole.user);
      expect(restored.status, MessageStatus.sent);
      expect(restored.content, 'Hello');
      expect(restored.isUser, isTrue);
    });

    test('unknown enum values fall back safely', () {
      final restored = ChatMessage.fromMap({
        'role': 'aliens',
        'status': 'teleported',
        'content': 'x',
      }, id: 'm2');
      expect(restored.role, MessageRole.system);
      expect(restored.status, MessageStatus.sent);
    });

    test('failed message carries error text', () {
      final failed = ChatMessage(
        id: 'm3',
        conversationId: 'c1',
        role: MessageRole.assistant,
        content: '',
        status: MessageStatus.failed,
        errorMessage: 'Provider timeout',
      );
      final restored = ChatMessage.fromMap(failed.toMap(), id: 'm3');
      expect(restored.isFailed, isTrue);
      expect(restored.errorMessage, 'Provider timeout');
    });
  });
}
