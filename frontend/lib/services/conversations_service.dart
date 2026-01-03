import 'dart:convert';
import '../models/conversation.dart';
import 'api_client.dart';

/// Service for managing conversations
class ConversationsService {
  final ApiClient _apiClient;

  ConversationsService(this._apiClient);

  /// GET /api/conversations
  /// Lister les conversations
  Future<List<Conversation>> getConversations() async {
    final response = await _apiClient.get('/api/conversations');
    final List<dynamic> data = jsonDecode(response.body);

    return data.map((json) => _conversationFromJson(json)).toList();
  }

  /// POST /api/conversations
  /// Créer une nouvelle conversation
  Future<Conversation> createConversation({
    required List<String> participantIds,
    String? title,
  }) async {
    final body = {
      'participantIds': participantIds,
      if (title != null) 'title': title,
    };

    final response = await _apiClient.post('/api/conversations', body: body);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return _conversationFromJson(json);
  }

  /// Convert JSON to Conversation model
  Conversation _conversationFromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

