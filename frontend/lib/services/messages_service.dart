import 'dart:convert';
import 'dart:typed_data';
import '../models/message.dart';
import 'api_client.dart';

/// Service for managing messages
class MessagesService {
  final ApiClient _apiClient;

  MessagesService(this._apiClient);

  /// GET /api/conversations/:id/messages?limit=50&offset=0
  /// Récupérer les messages d'une conversation (paginés)
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final response = await _apiClient.get(
      '/api/conversations/$conversationId/messages',
      queryParameters: queryParams,
    );

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => _messageFromJson(json)).toList();
  }

  /// POST /api/conversations/:id/messages
  /// Envoyer un message texte
  /// Body: { "type":"TEXT", "encryptedPayload": "base64-chiffre", "iv":"base64-iv", "plaintextPreview": "Bonjour", "meta": { "length": 12 } }
  Future<Message> sendTextMessage({
    required String conversationId,
    required String encryptedPayload, // base64-encoded encrypted payload
    required String iv, // base64-encoded IV
    String? plaintextPreview, // optional short preview for UI
    Map<String, dynamic>? meta, // optional metadata like length
  }) async {
    final body = <String, dynamic>{
      'type': 'TEXT',
      'encryptedPayload': encryptedPayload,
      'iv': iv,
    };

    if (plaintextPreview != null) {
      body['plaintextPreview'] = plaintextPreview;
    }

    if (meta != null) {
      body['meta'] = meta;
    }

    final response = await _apiClient.post(
      '/api/conversations/$conversationId/messages',
      body: body,
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _messageFromJson(json);
  }

  /// POST /api/conversations/:id/messages
  /// Envoyer un message audio (après chiffrement côté client)
  /// Option 1 - Client effectue transcription puis chiffre
  /// Body: { "type":"AUDIO", "encryptedPayloadUrl":"https://...", "iv":"base64-iv", "transcription": { "text":"...", "confidence":0.94 } }
  Future<Message> sendAudioMessage({
    required String conversationId,
    required String encryptedPayloadUrl, // URL du blob chiffré uploadé
    required String iv, // base64-encoded IV
    String? transcriptionText, // transcription fournie par le client
    double? transcriptionConfidence, // confidence de la transcription
  }) async {
    final body = <String, dynamic>{
      'type': 'AUDIO',
      'encryptedPayloadUrl': encryptedPayloadUrl,
      'iv': iv,
    };

    if (transcriptionText != null) {
      print('[DEBUG] Adding transcription to request body');
      body['transcription'] = <String, dynamic>{
        'text': transcriptionText,
      };
      if (transcriptionConfidence != null) {
        body['transcription']['confidence'] = transcriptionConfidence;
      }
      print('[DEBUG] Transcription in body: ${body['transcription']}');
    } else {
      print('[DEBUG] Warning: transcriptionText is null, not sending transcription');
    }

    print('[DEBUG] Sending POST request with body: ${jsonEncode(body)}');
    final response = await _apiClient.post(
      '/api/conversations/$conversationId/messages',
      body: body,
    );
    print('[DEBUG] Response received: ${response.statusCode}');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _messageFromJson(json);
  }

  /// POST /api/conversations/:id/messages?serverTranscribe=true
  /// Envoyer un message audio pour transcription côté serveur
  /// Option 2 - Server-side transcription
  /// multipart/form-data avec file=audio (en clair)
  /// Le serveur transcrit, chiffre, puis stocke
  Future<Message> sendAudioMessageForServerTranscription({
    required String conversationId,
    required Uint8List audioBytes, // Audio en clair (non chiffré)
    required String fileName,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/conversations/$conversationId/messages?serverTranscribe=true',
      fields: {},
      fileField: 'file', // Le backend attend 'file' dans multipart/form-data
      fileBytes: audioBytes,
      fileName: fileName,
      contentType: 'audio/m4a',
    );

    // Réponse 201 avec message créé (serveur fournit transcription)
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _messageFromJson(json);
  }

  /// GET /api/messages/:messageId
  /// Récupérer les métadonnées d'un message
  Future<Message> getMessage(String messageId) async {
    final response = await _apiClient.get('/api/messages/$messageId');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _messageFromJson(json);
  }

  /// GET /api/messages/:messageId/blob
  /// Récupérer le blob chiffré d'un message
  /// Retourne 302 redirect vers CDN ou 200 binary (application/octet-stream)
  /// Le backend doit vérifier que le demandeur fait partie de la conversation
  Future<Uint8List> getMessageBlob(String messageId) async {
    final response = await _apiClient.get('/api/messages/$messageId/blob');
    
    // Si c'est une redirection (302), le client HTTP devrait suivre automatiquement
    // Sinon, retourner les bytes directement
    return response.bodyBytes;
  }

  /// Convert JSON to Message model
  Message _messageFromJson(Map<String, dynamic> json) {
    // Extract transcription if available (can be in 'transcription' field as string or object)
    String? transcriptionText;
    double? transcriptionConfidence;
    
    final transcription = json['transcription'];
    if (transcription != null) {
      if (transcription is String) {
        transcriptionText = transcription;
      } else if (transcription is Map) {
        transcriptionText = transcription['text'] as String?;
        transcriptionConfidence = (transcription['confidence'] as num?)?.toDouble();
      }
    }
    
    return Message(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      type: _parseMessageType((json['type'] as String?) ?? 'TEXT'),
      encryptedBlobUrl: json['encryptedBlobUrl'] as String? ?? '',
      iv: json['iv'] as String? ?? '',
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      contentPreview: json['contentPreview'] as String?,
      transcriptionId: json['transcriptionId'] as String?,
      transcriptionText: transcriptionText,
      transcriptionConfidence: transcriptionConfidence,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// Parse message type from string
  MessageType _parseMessageType(String type) {
    switch (type.toUpperCase()) {
      case 'TEXT':
        return MessageType.text;
      case 'AUDIO':
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }
}

