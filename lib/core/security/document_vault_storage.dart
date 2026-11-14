import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'secure_encryption_service.dart';

class DocumentVaultStorage {
  final SecureEncryptionService _encryptionService;
  final Directory? _customBaseDir;

  DocumentVaultStorage({
    SecureEncryptionService? encryptionService,
    Directory? baseDirectory,
  }) : _encryptionService = encryptionService ?? SecureEncryptionService(),
       _customBaseDir = baseDirectory;

  Future<Directory> _getBaseDirectory() async {
    if (_customBaseDir != null) return _customBaseDir;
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  Future<String> saveEncryptedDocument({
    required String fileId,
    required Uint8List rawBytes,
  }) async {
    final docsDir = await _getBaseDirectory();
    final vaultFolder = Directory(p.join(docsDir.path, 'vault_encrypted'));
    if (!await vaultFolder.exists()) {
      await vaultFolder.create(recursive: true);
    }

    final targetPath = p.join(vaultFolder.path, '$fileId.enc');
    final encryptedBytes = await _encryptBytes(rawBytes);

    final file = File(targetPath);
    await file.writeAsBytes(encryptedBytes);
    return targetPath;
  }

  Future<Uint8List?> readDecryptedDocument(String encryptedPath) async {
    final file = File(encryptedPath);
    if (!await file.exists()) return null;

    try {
      final encryptedBytes = await file.readAsBytes();
      return await _decryptBytes(encryptedBytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteDocument(String encryptedPath) async {
    try {
      final file = File(encryptedPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<Uint8List> _encryptBytes(Uint8List plain) async {
    final keyStr = await _encryptionService.encrypt('master_vault_key');
    final keyBytes = utf8.encode(keyStr);
    final digest = sha256.convert(keyBytes).bytes;

    final result = Uint8List(plain.length);
    for (int i = 0; i < plain.length; i++) {
      result[i] = plain[i] ^ digest[i % digest.length];
    }
    return result;
  }

  Future<Uint8List> _decryptBytes(Uint8List encrypted) async {
    return _encryptBytes(encrypted);
  }
}
