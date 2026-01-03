// Stub file for file operations on web
// This file is used as a replacement when running on web platform
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';

Future<void> deleteFileIfExists(String path) async {
  // On web, files are stored in memory and don't need deletion
  return;
}

Future<Uint8List> readFileAsBytes(String path) async {
  // On web, path might be a blob URL
  if (path.startsWith('blob:')) {
    try {
      // Fetch the blob URL
      final response = await html.HttpRequest.request(
        path,
        responseType: 'arraybuffer',
      );
      // The response is a ByteBuffer when responseType is 'arraybuffer'
      final byteBuffer = response.response as ByteBuffer;
      return Uint8List.view(byteBuffer);
    } catch (e) {
      throw Exception('Failed to read blob URL on web: $e');
    }
  } else if (path.startsWith('data:')) {
    // Handle data URLs
    final base64Data = path.split(',')[1];
    return Uint8List.fromList(base64Decode(base64Data));
  } else {
    throw UnsupportedError('Unsupported file path format on web: $path');
  }
}

