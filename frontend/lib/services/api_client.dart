import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base API client for handling HTTP requests
class ApiClient {
  final String baseUrl;
  final String? authToken;
  final String? userId; // For prototype: X-User-Id header

  ApiClient({
    required this.baseUrl,
    this.authToken,
    this.userId,
  });

  /// Get base headers
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    if (userId != null) {
      headers['X-User-Id'] = userId!;
    }

    return headers;
  }

  /// GET request
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {..._headers, ...?headers};

    final response = await http.post(
      uri,
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response);
  }

  /// POST multipart request (for file uploads)
  Future<http.Response> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
    String? contentType,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers.addAll(_headers);
    request.headers.remove('Content-Type'); // Let multipart set it

    // Add fields
    request.fields.addAll(fields);

    // Add file
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
        contentType: contentType != null
            ? http.MediaType.parse(contentType)
            : null,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  /// Handle response and throw exceptions for errors
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    // Try to parse error message
    String errorMessage = 'Request failed with status ${response.statusCode}';
    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map && errorBody.containsKey('message')) {
        errorMessage = errorBody['message'];
      } else if (errorBody is Map && errorBody.containsKey('error')) {
        errorMessage = errorBody['error'];
      }
    } catch (_) {
      // If parsing fails, use default message
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      body: response.body,
    );
  }
}

/// API Exception class
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

