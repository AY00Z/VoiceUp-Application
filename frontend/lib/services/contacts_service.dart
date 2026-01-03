import 'dart:convert';
import '../models/user.dart';
import 'api_client.dart';

/// Service for managing contacts/friends
class ContactsService {
  final ApiClient _apiClient;

  ContactsService(this._apiClient);

  /// GET /api/contacts
  /// Récupérer la liste des contacts fictifs
  Future<List<User>> getContacts() async {
    final response = await _apiClient.get('/api/contacts');
    final List<dynamic> data = jsonDecode(response.body);

    return data.map((json) => _userFromJson(json)).toList();
  }

  /// Convert JSON to User model
  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['name'] as String, // Use name as displayName if not provided
      avatarUrl: json['avatarUrl'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

