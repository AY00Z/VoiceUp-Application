class Conversation {
  final String id; // UUID
  final String title;
  final List<String> participantIds; // List<UUID>
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.title,
    required this.participantIds,
    required this.createdAt,
  });
}

