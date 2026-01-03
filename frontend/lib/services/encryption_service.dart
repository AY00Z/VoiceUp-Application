import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Service for encrypting/decrypting messages
/// Uses AES-256-CBC encryption
class EncryptionService {
  // For demo purposes, we'll use a simple key
  // In production, this should be derived from a shared secret or key exchange
  static const String _defaultKeyString = '12345678901234567890123456789012'; // 32 bytes for AES-256
  
  late final encrypt.Key _key;

  EncryptionService({String? keyString}) {
    final keyStr = keyString ?? _defaultKeyString;
    // Ensure key is exactly 32 bytes for AES-256
    final keyBytes = utf8.encode(keyStr.padRight(32, '0').substring(0, 32));
    _key = encrypt.Key(keyBytes);
  }

  /// Generate a random IV (Initialization Vector)
  encrypt.IV _generateIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return encrypt.IV(Uint8List.fromList(ivBytes));
  }

  /// Encrypt text message
  /// Returns: Map with 'encryptedPayload' (base64) and 'iv' (base64)
  Map<String, String> encryptText(String plaintext) {
    final iv = _generateIV();
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    return {
      'encryptedPayload': encrypted.base64,
      'iv': iv.base64,
    };
  }

  /// Decrypt text message
  String decryptText(String encryptedBase64, String ivBase64) {
    try {
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt message: $e');
    }
  }

  /// Encrypt binary data (for audio files)
  /// Returns: Map with encrypted bytes and 'iv' (base64)
  Map<String, dynamic> encryptBinary(Uint8List data) {
    final iv = _generateIV();
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    
    // Encrypt the data
    // Note: For binary data, we need to handle padding carefully
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    return {
      'encryptedData': encrypted.bytes,
      'iv': iv.base64,
    };
  }

  /// Decrypt binary data (for audio files)
  Uint8List decryptBinary(Uint8List encryptedData, String ivBase64) {
    try {
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypted = encrypt.Encrypted(encryptedData);
      final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      // decryptBytes returns List<int>, convert to Uint8List
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt binary data: $e');
    }
  }

  /// Encrypt text and return base64-encoded payload with IV
  String encryptTextToBase64(String plaintext) {
    final result = encryptText(plaintext);
    return result['encryptedPayload']!;
  }

  /// Get IV as base64 string (helper method)
  String generateIVBase64() {
    return _generateIV().base64;
  }
}

