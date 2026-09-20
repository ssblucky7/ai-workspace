/// Centralized Firestore collection and document paths.
///
/// All user data is nested under `users/{uid}` so that security rules can
/// scope every read and write to the authenticated owner.
class FirestorePaths {
  FirestorePaths._();

  static String userDoc(String uid) => 'users/$uid';

  static String conversationsCol(String uid) => 'users/$uid/conversations';

  static String conversationDoc(String uid, String conversationId) =>
      'users/$uid/conversations/$conversationId';

  static String messagesCol(String uid, String conversationId) =>
      'users/$uid/conversations/$conversationId/messages';

  static String messageDoc(
    String uid,
    String conversationId,
    String messageId,
  ) => 'users/$uid/conversations/$conversationId/messages/$messageId';

  static String providersCol(String uid) => 'users/$uid/providers';

  static String providerDoc(String uid, String providerId) =>
      'users/$uid/providers/$providerId';
}
