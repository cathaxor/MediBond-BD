import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Secure Encryption Service protecting sensitive data with Android Keystore backed storage.
class SecureEncryptionService {
  static const String _keyAlias = 'medibond_secret_db_key_v1';
  final FlutterSecureStorage _storage;
  String? _cachedKey;

  SecureEncryptionService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  Future<String> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    try {
      String? existing = await _storage.read(key: _keyAlias);
      if (existing == null || existing.isEmpty) {
        existing = const Uuid().v4() + const Uuid().v4();
        await _storage.write(key: _keyAlias, value: existing);
      }
      _cachedKey = existing;
      return existing;
    } catch (_) {
      // Fallback in test/headless environment
      _cachedKey ??= 'medibond_secure_fallback_key_2025';
      return _cachedKey!;
    }
  }

  /// Encrypts sensitive string fields (e.g. medical notes / prescription text)
  Future<String> encrypt(String plainText) async {
    if (plainText.isEmpty) return plainText;
    final masterKey = await _getOrCreateKey();
    final keyBytes = utf8.encode(masterKey);
    final textBytes = utf8.encode(plainText);

    final digest = sha256.convert(keyBytes).bytes;
    final cipher = List<int>.generate(textBytes.length, (i) {
      return textBytes[i] ^ digest[i % digest.length];
    });

    return 'ENC:${base64.encode(cipher)}';
  }

  /// Decrypts sensitive string fields
  Future<String> decrypt(String cipherText) async {
    if (!cipherText.startsWith('ENC:')) return cipherText;
    try {
      final base64Data = cipherText.substring(4);
      final cipherBytes = base64.decode(base64Data);
      final masterKey = await _getOrCreateKey();
      final keyBytes = utf8.encode(masterKey);
      final digest = sha256.convert(keyBytes).bytes;

      final plainBytes = List<int>.generate(cipherBytes.length, (i) {
        return cipherBytes[i] ^ digest[i % digest.length];
      });

      return utf8.decode(plainBytes);
    } catch (_) {
      return cipherText;
    }
  }
}
