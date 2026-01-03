enum MessageType {
  text,
  audio,
}

class Message {
  final String id; // UUID
  final String conversationId; // UUID
  final String senderId; // UUID
  final MessageType type; // TEXT | AUDIO
  final String encryptedBlobUrl;
  final String iv;
  final bool isEncrypted;
  final String? contentPreview; // optional, short preview for UI
  final String? transcriptionId; // UUID, optional
  final String? transcriptionText; // Transcription text from STT_API
  final double? transcriptionConfidence; // Confidence score from STT_API
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.encryptedBlobUrl,
    required this.iv,
    required this.isEncrypted,
    this.contentPreview,
    this.transcriptionId,
    this.transcriptionText,
    this.transcriptionConfidence,
    required this.createdAt,
    required this.isRead,
  });
}
