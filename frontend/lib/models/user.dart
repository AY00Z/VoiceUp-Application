class User {
  final String id; // UUID
  final String name;
  final String displayName;
  final String avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.displayName,
    required this.avatarUrl,
    required this.createdAt,
  });
}

