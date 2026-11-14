import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/family_member.dart';
import '../../data/models/medicine.dart';
import '../../data/models/prescription.dart';
import '../../data/providers/database_providers.dart';
import '../../data/repositories/dose_event_repository.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../notifications/notification_service.dart';
import 'document_vault_storage.dart';

enum RestoreMode { replace, merge }

class BackupPreviewData {
  final int profilesCount;
  final int medicinesCount;
  final int doseLogsCount;
  final int prescriptionsCount;
  final int filesCount;
  final String userId;
  final DateTime createdAt;
  final Map<String, dynamic> rawPayload;

  BackupPreviewData({
    required this.profilesCount,
    required this.medicinesCount,
    required this.doseLogsCount,
    required this.prescriptionsCount,
    required this.filesCount,
    required this.userId,
    required this.createdAt,
    required this.rawPayload,
  });
}

class BackupService {
  final ProfileRepository profileRepo;
  final MedicineRepository medicineRepo;
  final DoseEventRepository doseEventRepo;
  final PrescriptionRepository prescriptionRepo;
  final DocumentVaultStorage vaultStorage;

  static const int pbkdf2Iterations = 100000;
  static const int keyLength = 32;

  BackupService({
    required this.profileRepo,
    required this.medicineRepo,
    required this.doseEventRepo,
    required this.prescriptionRepo,
    required this.vaultStorage,
  });

  /// Derives 256-bit AES Key from password + salt using PBKDF2-HMAC-SHA256
  Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: pbkdf2Iterations,
      bits: keyLength * 8,
    );

    final secretKey = SecretKey(utf8.encode(password));
    return await pbkdf2.deriveKey(secretKey: secretKey, nonce: salt);
  }

  /// Exports active local database data and prescription vault files into an encrypted .medibond file
  Future<Uint8List> createEncryptedBackup({
    required String password,
    required String userId,
  }) async {
    final profiles = await profileRepo.getAllProfiles();
    final medicines = await medicineRepo.getAllMedicines();
    final logs = await doseEventRepo.getAllLogs();
    final prescriptions = await prescriptionRepo.getAllPrescriptions();

    final vaultFiles = <String, String>{};
    for (var rx in prescriptions) {
      if (rx.imageUrl != null && rx.imageUrl!.isNotEmpty) {
        final filename = rx.imageUrl!;
        final fileBytes = await vaultStorage.readDecryptedDocument(filename);
        if (fileBytes != null) {
          vaultFiles[filename] = base64Encode(fileBytes);
        }
      }
    }

    final payloadMap = {
      'version': 1,
      'app': 'MediBond BD',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'userId': userId,
      'profiles': profiles
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'relationship': p.relationship,
              'relationshipBn': p.relationshipBn,
              'age': p.calculatedAge,
              'birthYear': p.birthYear,
              'dateOfBirth': p.dateOfBirth?.toIso8601String(),
              'gender': p.gender,
              'bloodGroup': p.bloodGroup,
              'heightCm': p.heightCm,
              'weightKg': p.weightKg,
              'allergies': p.allergies,
              'emergencyContact': p.emergencyContact,
              'emergencyName': p.emergencyName,
              'emergencyRelationship': p.emergencyRelationship,
              'medicalNotes': p.encodeMedicalNotesPayload(),
              'avatarInitials': p.avatarInitials,
              'avatarColorValue': p.avatarColorValue,
            },
          )
          .toList(),
      'medicines': medicines
          .map(
            (m) => {
              'id': m.id,
              'name': m.name,
              'strength': m.strength,
              'form': m.form.name,
              'dosage': m.dosage,
              'instructions': m.instructions.name,
              'timesPerDay': m.timesPerDay,
              'scheduledTimes': m.scheduledTimes
                  .map((t) => '${t.hour}:${t.minute}')
                  .toList(),
              'familyMemberId': m.familyMemberId,
              'stockCount': m.stockCount,
              'reorderThreshold': m.reorderThreshold,
              'colorHex': m.colorHex,
              'isActive': m.isActive,
              'isPaused': m.isPaused,
              'startDate': m.startDate.toIso8601String(),
              'endDate': m.endDate?.toIso8601String(),
              'weekdays': m.weekdays,
              'notes': m.notes,
            },
          )
          .toList(),
      'doseEvents': logs
          .map(
            (l) => {
              'id': l.id,
              'medicineId': l.medicineId,
              'medicineName': l.medicineName,
              'familyMemberId': l.familyMemberId,
              'dosage': l.dosage,
              'form': l.form.name,
              'instructions': l.instructions.name,
              'scheduledDateTime': l.scheduledDateTime.toIso8601String(),
              'status': l.status.name,
              'actionTime': l.actionTime?.toIso8601String(),
            },
          )
          .toList(),
      'prescriptions': prescriptions
          .map(
            (r) => {
              'id': r.id,
              'title': r.title,
              'doctorName': r.doctorName,
              'hospitalName': r.hospitalName,
              'date': r.date.toIso8601String(),
              'familyMemberId': r.familyMemberId,
              'notes': r.notes,
              'tags': r.tags,
              'imageUrl': r.imageUrl,
            },
          )
          .toList(),
      'vaultFiles': vaultFiles,
    };

    final rawJsonString = jsonEncode(payloadMap);
    final rawJsonBytes = utf8.encode(rawJsonString);

    final algorithm = Cryptography.instance.aesGcm(secretKeyLength: 32);
    final nonce = algorithm.newNonce();
    final salt = algorithm.newNonce();

    final derivedKey = await _deriveKey(password, salt);

    final secretBox = await algorithm.encrypt(
      rawJsonBytes,
      secretKey: derivedKey,
      nonce: nonce,
    );

    final envelope = {
      'formatVersion': 1,
      'app': 'MediBond BD',
      'appVersion': '1.0.0',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'userId': userId,
      'saltHex': _bytesToHex(salt),
      'nonceHex': _bytesToHex(secretBox.nonce),
      'macHex': _bytesToHex(secretBox.mac.bytes),
      'ciphertextBase64': base64Encode(secretBox.cipherText),
    };

    final envelopeString = jsonEncode(envelope);
    return Uint8List.fromList(utf8.encode(envelopeString));
  }

  /// Parses and decrypts a .medibond backup envelope for preview/validation
  Future<BackupPreviewData> previewEncryptedBackup({
    required Uint8List backupBytes,
    required String password,
    required String activeUserId,
  }) async {
    final jsonString = utf8.decode(backupBytes);
    final Map<String, dynamic> envelope = jsonDecode(jsonString);

    if (envelope['app'] != 'MediBond BD' || envelope['formatVersion'] != 1) {
      throw const FormatException(
        'Invalid or unsupported .medibond backup file format.',
      );
    }

    final backupUserId = envelope['userId']?.toString() ?? '';
    if (activeUserId.isNotEmpty &&
        backupUserId.isNotEmpty &&
        activeUserId != backupUserId) {
      throw StateError(
        'Backup belongs to a different user account ($backupUserId). Cross-account restore rejected.',
      );
    }

    final salt = _hexToBytes(envelope['saltHex']?.toString() ?? '');
    final nonce = _hexToBytes(envelope['nonceHex']?.toString() ?? '');
    final macBytes = _hexToBytes(envelope['macHex']?.toString() ?? '');
    final ciphertext = base64Decode(
      envelope['ciphertextBase64']?.toString() ?? '',
    );

    final derivedKey = await _deriveKey(password, salt);
    final algorithm = Cryptography.instance.aesGcm(secretKeyLength: 32);

    SecretBox secretBox;
    try {
      secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(macBytes));
    } catch (_) {
      throw const FormatException('Corrupted backup file envelope.');
    }

    List<int> decryptedBytes;
    try {
      decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: derivedKey,
      );
    } catch (_) {
      throw const FormatException(
        'Incorrect backup password or tampered file.',
      );
    }

    final decryptedString = utf8.decode(decryptedBytes);
    final Map<String, dynamic> payload = jsonDecode(decryptedString);

    final profiles = payload['profiles'] as List? ?? [];
    final medicines = payload['medicines'] as List? ?? [];
    final doseEvents = payload['doseEvents'] as List? ?? [];
    final prescriptions = payload['prescriptions'] as List? ?? [];
    final vaultFiles = payload['vaultFiles'] as Map? ?? {};

    return BackupPreviewData(
      profilesCount: profiles.length,
      medicinesCount: medicines.length,
      doseLogsCount: doseEvents.length,
      prescriptionsCount: prescriptions.length,
      filesCount: vaultFiles.length,
      userId: backupUserId,
      createdAt:
          DateTime.tryParse(payload['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      rawPayload: payload,
    );
  }

  /// Restores decrypted payload into local Drift SQLite database and prescription vault
  Future<void> restoreBackupData({
    required BackupPreviewData preview,
    required RestoreMode mode,
  }) async {
    final payload = preview.rawPayload;

    if (mode == RestoreMode.replace) {
      final existingProfiles = await profileRepo.getAllProfiles();
      for (var p in existingProfiles) {
        await profileRepo.deleteProfile(p.id);
      }
      final existingMeds = await medicineRepo.getAllMedicines();
      for (var m in existingMeds) {
        await medicineRepo.deleteMedicine(m.id);
      }
      final existingLogs = await doseEventRepo.getAllLogs();
      for (var l in existingLogs) {
        await doseEventRepo.deleteLog(l.id);
      }
      final existingRx = await prescriptionRepo.getAllPrescriptions();
      for (var r in existingRx) {
        await prescriptionRepo.deletePrescription(r.id);
      }
    }

    // Restore Profiles
    final rawProfiles = payload['profiles'] as List? ?? [];
    for (var r in rawProfiles) {
      final member = FamilyMember.fromParsedData(
        id: r['id']?.toString() ?? '',
        name: r['name']?.toString() ?? '',
        relationship: r['relationship']?.toString() ?? 'Self',
        relationshipBn: r['relationshipBn']?.toString() ?? 'আমি',
        age: (r['age'] as num?)?.toInt() ?? 30,
        birthYear: (r['birthYear'] as num?)?.toInt(),
        bloodGroup: r['bloodGroup']?.toString() ?? 'Not Set',
        avatarInitials: r['avatarInitials']?.toString() ?? 'FM',
        avatarColorValue:
            (r['avatarColorValue'] as num?)?.toInt() ?? 0xFF087F79,
        emergencyContact: r['emergencyContact']?.toString() ?? '',
        decryptedPayload: r['medicalNotes']?.toString() ?? '',
      );
      await profileRepo.saveProfile(member);
    }

    // Restore Medicines
    final rawMeds = payload['medicines'] as List? ?? [];
    for (var r in rawMeds) {
      final timesList = (r['scheduledTimes'] as List? ?? []).map((tStr) {
        final parts = tStr.toString().split(':');
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }).toList();

      final med = Medicine(
        id: r['id']?.toString() ?? '',
        name: r['name']?.toString() ?? '',
        strength: r['strength']?.toString() ?? '',
        form: MedicineForm.values.firstWhere(
          (f) => f.name == r['form'],
          orElse: () => MedicineForm.tablet,
        ),
        dosage: r['dosage']?.toString() ?? '1 Tablet',
        instructions: MealInstruction.values.firstWhere(
          (i) => i.name == r['instructions'],
          orElse: () => MealInstruction.afterFood,
        ),
        timesPerDay: (r['timesPerDay'] as num?)?.toInt() ?? 1,
        scheduledTimes: timesList.isEmpty
            ? [const TimeOfDay(hour: 8, minute: 30)]
            : timesList,
        familyMemberId: r['familyMemberId']?.toString() ?? '',
        stockCount: (r['stockCount'] as num?)?.toInt() ?? 20,
        reorderThreshold: (r['reorderThreshold'] as num?)?.toInt() ?? 5,
        colorHex: (r['colorHex'] as num?)?.toInt() ?? 0xFF087F79,
        isActive: r['isActive'] as bool? ?? true,
        isPaused: r['isPaused'] as bool? ?? false,
        startDate:
            DateTime.tryParse(r['startDate']?.toString() ?? '') ??
            DateTime.now(),
        endDate: r['endDate'] != null
            ? DateTime.tryParse(r['endDate'].toString())
            : null,
        weekdays: (r['weekdays'] as List? ?? [1, 2, 3, 4, 5, 6, 7]).cast<int>(),
        notes: r['notes']?.toString() ?? '',
      );
      await medicineRepo.saveMedicine(med);
    }

    // Restore Prescriptions & Vault Files
    final rawRx = payload['prescriptions'] as List? ?? [];
    final vaultFiles = payload['vaultFiles'] as Map<String, dynamic>? ?? {};

    for (var filename in vaultFiles.keys) {
      final fileBase64 = vaultFiles[filename]?.toString() ?? '';
      if (fileBase64.isNotEmpty) {
        final fileBytes = base64Decode(fileBase64);
        await vaultStorage.saveEncryptedDocument(
          fileId: filename.replaceAll('.enc', ''),
          rawBytes: fileBytes,
        );
      }
    }

    for (var r in rawRx) {
      final rx = Prescription(
        id: r['id']?.toString() ?? '',
        title: r['title']?.toString() ?? '',
        doctorName: r['doctorName']?.toString() ?? '',
        hospitalName: r['hospitalName']?.toString() ?? '',
        date: DateTime.tryParse(r['date']?.toString() ?? '') ?? DateTime.now(),
        familyMemberId: r['familyMemberId']?.toString() ?? '',
        notes: r['notes']?.toString() ?? '',
        tags: (r['tags'] as List? ?? []).cast<String>(),
        imageUrl: r['imageUrl']?.toString(),
      );
      await prescriptionRepo.savePrescription(rx);
    }

    // Reconcile Local Reminders
    await NotificationService().reconcileAndRestoreAlarms(
      await medicineRepo.getAllMedicines(),
    );
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    profileRepo: ref.watch(profileRepositoryProvider),
    medicineRepo: ref.watch(medicineRepositoryProvider),
    doseEventRepo: ref.watch(doseEventRepositoryProvider),
    prescriptionRepo: ref.watch(prescriptionRepositoryProvider),
    vaultStorage: DocumentVaultStorage(),
  );
});
