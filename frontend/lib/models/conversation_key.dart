class ConversationKey {
  final String id; // UUID
  final String conversationId; // UUID
  final Map<String, String> keys; // map<userId, encryptedKeyForUser>
  final DateTime createdAt;

  ConversationKey({
    required this.id,
    required this.conversationId,
    required this.keys,
    required this.createdAt,
  });
}

