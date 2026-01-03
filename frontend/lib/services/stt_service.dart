import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service for Speech-to-Text transcription using STT_API
class SttService {
  // STT_API runs on port 5001 (different from main backend on 5000)
  static const String sttBaseUrl = 'http://127.0.0.1:5001';

  /// Transcribe an audio file using STT_API
  /// 
  /// [audioBytes] - The audio file as bytes (WAV, MP3, M4A, FLAC, OGG, WebM)
  /// [fileName] - Optional filename for the audio file
  /// 
  /// Returns a map with:
  /// - 'text': The transcribed text
  /// - 'confidence': Confidence score (0.0 to 1.0)
  /// - 'segments': List of segments with timestamps
  /// - 'info': Additional info (language, etc.)
  Future<Map<String, dynamic>> transcribeAudio({
    required Uint8List audioBytes,
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('$sttBaseUrl/transcribe');
      final request = http.MultipartRequest('POST', uri);
      
      // Add audio file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: fileName ?? 'audio.wav',
        ),
      );

      print('Sending audio to STT_API: ${audioBytes.length} bytes');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception('STT_API error: ${errorBody['error'] ?? response.statusCode}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      print('STT_API transcription result: ${result['transcription']}');
      
      return {
        'text': result['transcription'] as String? ?? '',
        'confidence': result['confidence'] as double?,
        'segments': result['segments'] as List<dynamic>? ?? [],
        'info': result['info'] as Map<String, dynamic>? ?? {},
      };
    } catch (e) {
      print('Error calling STT_API: $e');
      rethrow;
    }
  }

  /// Check if STT_API is available
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$sttBaseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      print('STT_API health check failed: $e');
      return false;
    }
  }
}

