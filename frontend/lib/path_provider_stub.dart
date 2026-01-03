// Stub file for path_provider on web
// This file is used as a replacement when running on web platform
// Note: This function should never be called on web as we check kIsWeb before using it

// Create a minimal Directory-like class for web
class Directory {
  final String path;
  Directory(this.path);
}

Future<Directory> getApplicationDocumentsDirectory() {
  throw UnsupportedError('getApplicationDocumentsDirectory is not supported on web');
}

Future<Directory> getTemporaryDirectory() {
  throw UnsupportedError('getTemporaryDirectory is not supported on web');
}

