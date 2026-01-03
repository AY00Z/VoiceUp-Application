// Helper file for file operations on non-web platforms
import 'dart:io';
import 'dart:typed_data';

Future<void> deleteFileIfExists(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    print('Error deleting file: $e');
  }
}

Future<Uint8List> readFileAsBytes(String path) async {
  final file = File(path);
  return await file.readAsBytes();
}

