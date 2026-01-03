class Transcription {
  final String id; // UUID
  final String messageId; // UUID
  final String text;
  final double confidence;
  final DateTime createdAt;

  Transcription({
    required this.id,
    required this.messageId,
    required this.text,
    required this.confidence,
    required this.createdAt,
  });
}

