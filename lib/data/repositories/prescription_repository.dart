import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/security/document_vault_storage.dart';
import '../../core/security/secure_encryption_service.dart';
import '../database/app_database.dart';
import '../models/prescription.dart';

abstract class PrescriptionRepository {
  Future<List<Prescription>> getAllPrescriptions();
  Future<void> savePrescription(Prescription rx, {Uint8List? rawDocumentBytes});
  Future<void> updatePrescriptionTitle(String id, String newTitle);
  Future<void> deletePrescription(String id);
  Future<Uint8List?> loadDecryptedDocument(String imagePath);
  Future<void> seedInitialPrescriptionsIfEmpty(
    List<Prescription> defaultRxList,
  );
}

class DriftPrescriptionRepository implements PrescriptionRepository {
  final AppDatabase _db;
  final SecureEncryptionService _encryption;
  final DocumentVaultStorage _vaultStorage;

  DriftPrescriptionRepository(
    this._db,
    this._encryption, {
    DocumentVaultStorage? vaultStorage,
  }) : _vaultStorage =
           vaultStorage ?? DocumentVaultStorage(encryptionService: _encryption);

  @override
  Future<List<Prescription>> getAllPrescriptions() async {
    final rows = await _db.select(_db.prescriptions).get();
    final result = <Prescription>[];

    for (var r in rows) {
      final decryptedNotes = await _encryption.decrypt(r.notes);
      final tagList = r.tags.isNotEmpty ? r.tags.split(',') : <String>[];

      result.add(
        Prescription(
          id: r.id,
          title: r.title,
          doctorName: r.doctorName,
          hospitalName: r.hospitalName,
          date: r.date.toLocal(),
          familyMemberId: r.profileId,
          notes: decryptedNotes,
          tags: tagList,
          imageUrl: r.imagePath,
        ),
      );
    }
    return result;
  }

  @override
  Future<void> savePrescription(
    Prescription rx, {
    Uint8List? rawDocumentBytes,
  }) async {
    final encryptedNotes = await _encryption.encrypt(rx.notes);
    final now = DateTime.now().toUtc();
    final rxId = rx.id.isEmpty ? const Uuid().v4() : rx.id;
    final tagString = rx.tags.join(',');

    String? encPath = rx.imageUrl;
    if (rawDocumentBytes != null && rawDocumentBytes.isNotEmpty) {
      encPath = await _vaultStorage.saveEncryptedDocument(
        fileId: rxId,
        rawBytes: rawDocumentBytes,
      );
    }

    await _db
        .into(_db.prescriptions)
        .insertOnConflictUpdate(
          PrescriptionsCompanion(
            id: Value(rxId),
            profileId: Value(rx.familyMemberId),
            title: Value(rx.title),
            doctorName: Value(rx.doctorName),
            hospitalName: Value(rx.hospitalName),
            date: Value(rx.date.toUtc()),
            notes: Value(encryptedNotes),
            tags: Value(tagString),
            imagePath: Value(encPath),
            createdAt: Value(now),
          ),
        );
  }

  @override
  Future<void> updatePrescriptionTitle(String id, String newTitle) async {
    await (_db.update(_db.prescriptions)..where((p) => p.id.equals(id))).write(
      PrescriptionsCompanion(title: Value(newTitle)),
    );
  }

  @override
  Future<void> deletePrescription(String id) async {
    final row = await (_db.select(
      _db.prescriptions,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row != null && row.imagePath != null && row.imagePath!.isNotEmpty) {
      await _vaultStorage.deleteDocument(row.imagePath!);
    }
    await (_db.delete(_db.prescriptions)..where((p) => p.id.equals(id))).go();
  }

  @override
  Future<Uint8List?> loadDecryptedDocument(String imagePath) async {
    return await _vaultStorage.readDecryptedDocument(imagePath);
  }

  @override
  Future<void> seedInitialPrescriptionsIfEmpty(
    List<Prescription> defaultRxList,
  ) async {
    final existing = await _db.select(_db.prescriptions).get();
    if (existing.isEmpty) {
      for (var rx in defaultRxList) {
        await savePrescription(rx);
      }
    }
  }
}
