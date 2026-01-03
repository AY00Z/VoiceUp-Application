import '../services/api_service.dart';

/// API Configuration
class ApiConfig {
  // Change this to your backend URL
  // Backend Flask runs on port 5000 by default
  static const String baseUrl = 'http://127.0.0.1:5000';
  
  // For prototype: use X-User-Id header
  // In production, use proper authentication token
  static String? userId;
  static String? authToken;

  /// Initialize API service with configuration
  static ApiService createApiService() {
    return ApiService(
      baseUrl: baseUrl,
      authToken: authToken,
      userId: userId ?? 'me', // Default to 'me' for prototype
    );
  }
}

