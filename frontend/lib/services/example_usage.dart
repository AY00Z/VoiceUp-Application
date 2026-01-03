// Example usage of API services
// This file shows how to use the services in your app

import '../config/api_config.dart';
import '../models/user.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'dart:typed_data';

/// Example: How to use the API services
class ApiUsageExamples {
  final apiService = ApiConfig.createApiService();

  /// Example 1: Get contacts
  Future<void> exampleGetContacts() async {
    try {
      final contacts = await apiService.contacts.getContacts();
      print('Found ${contacts.length} contacts');
      for (final contact in contacts) {
        print('Contact: ${contact.name} (${contact.id})');
      }
    } catch (e) {
      print('Error getting contacts: $e');
    }
  }

  /// Example 2: Get conversations
  Future<void> exampleGetConversations() async {
    try {
      final conversations = await apiService.conversations.getConversations();
      print('Found ${conversations.length} conversations');
      for (final conv in conversations) {
        print('Conversation: ${conv.title} (${conv.id})');
      }
    } catch (e) {
      print('Error getting conversations: $e');
    }
  }

  /// Example 3: Get messages from a conversation
  Future<void> exampleGetMessages(String conversationId) async {
    try {
      final messages = await apiService.messages.getMessages(
        conversationId,
        limit: 50,
        offset: 0,
      );
      print('Found ${messages.length} messages');
      for (final message in messages) {
        print('Message: ${message.contentPreview ?? "Audio"}');
      }
    } catch (e) {
      print('Error getting messages: $e');
    }
  }

  /// Example 4: Send a text message
  Future<void> exampleSendTextMessage(String conversationId) async {
    try {
      // In real app, you would encrypt the message first
      const plaintext = 'Hello!';
      const encryptedPayload = 'base64-encrypted-payload'; // Encrypt this
      const iv = 'base64-iv'; // Generate IV

      final message = await apiService.messages.sendTextMessage(
        conversationId: conversationId,
        encryptedPayload: encryptedPayload,
        iv: iv,
        plaintextPreview: plaintext,
      );

      print('Message sent: ${message.id}');
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Example 5: Send an audio message (client-side encryption)
  Future<void> exampleSendAudioMessage(
    String conversationId,
    Uint8List encryptedAudioBytes,
    String transcription,
  ) async {
    try {
      // First, upload the encrypted blob
      final blobUrl = await apiService.uploads.uploadAudioBlob(
        encryptedAudioBytes: encryptedAudioBytes,
        fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.enc',
      );

      // Then send the message with transcription
      const iv = 'base64-iv'; // Generate IV during encryption

      final message = await apiService.messages.sendAudioMessage(
        conversationId: conversationId,
        encryptedPayloadUrl: blobUrl,
        iv: iv,
        transcriptionText: transcription,
        transcriptionConfidence: 0.95,
      );

      print('Audio message sent: ${message.id}');
    } catch (e) {
      print('Error sending audio message: $e');
    }
  }

  /// Example 6: Send audio for server-side transcription
  Future<void> exampleSendAudioForServerTranscription(
    String conversationId,
    Uint8List audioBytes,
  ) async {
    try {
      final message = await apiService.messages.sendAudioMessageForServerTranscription(
        conversationId: conversationId,
        audioBytes: audioBytes,
        fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      print('Audio message sent (server transcription): ${message.id}');
      if (message.transcriptionId != null) {
        print('Transcription ID: ${message.transcriptionId}');
      }
    } catch (e) {
      print('Error sending audio: $e');
    }
  }

  /// Example 7: Get transcription
  Future<void> exampleGetTranscription(String messageId) async {
    try {
      final transcription = await apiService.transcriptions.getTranscription(messageId);
      print('Transcription: ${transcription.text}');
      print('Confidence: ${transcription.confidence}');
    } catch (e) {
      print('Error getting transcription: $e');
    }
  }

  /// Example 8: Search in conversation
  Future<void> exampleSearch(String conversationId, String query) async {
    try {
      final results = await apiService.search.search(
        conversationId: conversationId,
        query: query,
      );

      print('Found ${results.length} results');
      for (final result in results) {
        print('Result: ${result.excerpt}');
        print('Message ID: ${result.messageId}');
      }
    } catch (e) {
      print('Error searching: $e');
    }
  }

  /// Example 9: Get message blob (encrypted audio)
  Future<void> exampleGetMessageBlob(String messageId) async {
    try {
      final blob = await apiService.messages.getMessageBlob(messageId);
      print('Received blob of ${blob.length} bytes');
      // Decrypt the blob here
    } catch (e) {
      print('Error getting blob: $e');
    }
  }

  /// Example 10: Check API health
  Future<void> exampleCheckHealth() async {
    try {
      final isHealthy = await apiService.checkHealth();
      if (isHealthy) {
        print('API is healthy');
      } else {
        print('API is not responding');
      }
    } catch (e) {
      print('Error checking health: $e');
    }
  }
}

