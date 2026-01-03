import 'dart:convert';
import 'api_client.dart';
import 'contacts_service.dart';
import 'conversations_service.dart';
import 'messages_service.dart';
import 'transcription_service.dart';
import 'search_service.dart';
import 'upload_service.dart';
import 'stt_service.dart';

/// Main API service that aggregates all services
class ApiService {
  late ApiClient _apiClient;
  late ContactsService contacts;
  late ConversationsService conversations;
  late MessagesService messages;
  late TranscriptionService transcriptions;
  late SearchService search;
  late UploadService uploads;
  late SttService stt;

  ApiService({
    required String baseUrl,
    String? authToken,
    String? userId,
  }) {
    _apiClient = ApiClient(
      baseUrl: baseUrl,
      authToken: authToken,
      userId: userId,
    );

    contacts = ContactsService(_apiClient);
    conversations = ConversationsService(_apiClient);
    messages = MessagesService(_apiClient);
    transcriptions = TranscriptionService(_apiClient);
    search = SearchService(_apiClient);
    uploads = UploadService(_apiClient);
    stt = SttService();
  }

  /// GET /api/health
  /// Vérifier que l'API fonctionne
  /// Returns false if endpoint doesn't exist (404) or server is unreachable
  Future<bool> checkHealth() async {
    try {
      final response = await _apiClient.get('/api/health');
      return response.statusCode == 200;
    } catch (e) {
      // If it's a 404, the endpoint doesn't exist but server might be reachable
      // If it's a connection error, server is not reachable
      final errorStr = e.toString();
      if (errorStr.contains('404') || errorStr.contains('NOT FOUND')) {
        // Endpoint doesn't exist, but server is reachable
        // Return true to allow other endpoints to be tried
        return true;
      }
      // Connection error - server not reachable
      return false;
    }
  }

  /// GET /api/version
  /// Récupérer la version du backend
  Future<String> getVersion() async {
    final response = await _apiClient.get('/api/version');
    final json = response.body;
    // Assuming version is returned as plain text or JSON
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map && decoded.containsKey('version')) {
        return decoded['version'] as String;
      }
    } catch (_) {
      // If not JSON, return as is
    }
    return json;
  }

  /// Update authentication token
  void updateAuthToken(String? token) {
    _apiClient = ApiClient(
      baseUrl: _apiClient.baseUrl,
      authToken: token,
      userId: _apiClient.userId,
    );

    // Recreate services with new client
    contacts = ContactsService(_apiClient);
    conversations = ConversationsService(_apiClient);
    messages = MessagesService(_apiClient);
    transcriptions = TranscriptionService(_apiClient);
    search = SearchService(_apiClient);
    uploads = UploadService(_apiClient);
    // STT service doesn't need recreation (it's independent)
  }

  /// Update user ID
  void updateUserId(String? userId) {
    _apiClient = ApiClient(
      baseUrl: _apiClient.baseUrl,
      authToken: _apiClient.authToken,
      userId: userId,
    );

    // Recreate services with new client
    contacts = ContactsService(_apiClient);
    conversations = ConversationsService(_apiClient);
    messages = MessagesService(_apiClient);
    transcriptions = TranscriptionService(_apiClient);
    search = SearchService(_apiClient);
    uploads = UploadService(_apiClient);
    // STT service doesn't need recreation (it's independent)
  }
}

