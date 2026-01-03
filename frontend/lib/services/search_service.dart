import 'dart:convert';
import 'api_client.dart';

/// Search result model
class SearchResult {
  final String messageId;
  final String excerpt;
  final String type; // TEXT or AUDIO
  final DateTime createdAt;

  SearchResult({
    required this.messageId,
    required this.excerpt,
    required this.type,
    required this.createdAt,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      messageId: json['messageId'] as String,
      excerpt: json['excerpt'] as String,
      type: json['type'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Service for searching messages
class SearchService {
  final ApiClient _apiClient;

  SearchService(this._apiClient);

  /// GET /api/search?conversationId=:id&q=mot
  /// Rechercher dans les messages et transcriptions
  Future<List<SearchResult>> search({
    required String conversationId,
    required String query,
  }) async {
    final queryParams = {
      'conversationId': conversationId,
      'q': query,
    };

    final response = await _apiClient.get(
      '/api/search',
      queryParameters: queryParams,
    );

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((json) => SearchResult.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

