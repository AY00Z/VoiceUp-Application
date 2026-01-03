import 'dart:convert';
import 'dart:typed_data';
import 'api_client.dart';

/// Service for uploading media files
class UploadService {
  final ApiClient _apiClient;

  UploadService(this._apiClient);

  /// POST /api/uploads
  /// Uploader un fichier (multipart/form-data file)
  /// Retourne l'URL du fichier stocké (CDN/S3)
  /// Utilisé pour stocker les blobs chiffrés
  Future<String> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    String? contentType,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/uploads',
      fields: {},
      fileField: 'file', // Le backend attend 'file' dans multipart/form-data
      fileBytes: fileBytes,
      fileName: fileName,
      contentType: contentType ?? 'application/octet-stream',
    );

    // Réponse: { "url": "https://cdn.../file.enc" }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['url'] as String;
  }

  /// Upload audio file (encrypted blob)
  Future<String> uploadAudioBlob({
    required Uint8List encryptedAudioBytes,
    required String fileName,
  }) async {
    return uploadFile(
      fileBytes: encryptedAudioBytes,
      fileName: fileName,
      contentType: 'application/octet-stream',
    );
  }
}

