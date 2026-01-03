import 'dart:convert';
import 'dart:typed_data';
import '../models/transcription.dart';
import 'api_client.dart';

/// Service for managing transcriptions
class TranscriptionService {
  final ApiClient _apiClient;

  TranscriptionService(this._apiClient);

  /// GET /api/messages/:messageId/transcription
  /// Récupérer la transcription d'un message
  Future<Transcription> getTranscription(String messageId) async {
    final response = await _apiClient.get('/api/messages/$messageId/transcription');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _transcriptionFromJson(json);
  }

  /// POST /api/transcribe
  /// Transcrire un fichier audio (optionnel, si service exposé)
  Future<TranscriptionResult> transcribeAudio({
    required Uint8List audioBytes,
    required String fileName,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/transcribe',
      fields: {},
      fileField: 'file',
      fileBytes: audioBytes,
      fileName: fileName,
      contentType: 'audio/m4a',
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return TranscriptionResult(
      text: json['text'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert JSON to Transcription model
  Transcription _transcriptionFromJson(Map<String, dynamic> json) {
    return Transcription(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      text: json['text'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Result of transcription request
class TranscriptionResult {
  final String text;
  final double confidence;

  TranscriptionResult({
    required this.text,
    required this.confidence,
  });
}

