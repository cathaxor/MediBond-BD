import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/security/secure_encryption_service.dart';
import '../database/app_database.dart';
import '../models/family_member.dart';

abstract class ProfileRepository {
  Future<List<FamilyMember>> getAllProfiles();
  Future<FamilyMember?> getProfileById(String id);
  Future<void> saveProfile(FamilyMember profile);
  Future<void> deleteProfile(String id);
  Future<void> seedInitialProfilesIfEmpty(List<FamilyMember> defaultMembers);
}

class DriftProfileRepository implements ProfileRepository {
  final AppDatabase _db;
  final SecureEncryptionService _encryption;

  DriftProfileRepository(this._db, this._encryption);

  @override
  Future<List<FamilyMember>> getAllProfiles() async {
    final rows = await _db.select(_db.profiles).get();
    final result = <FamilyMember>[];

    for (var r in rows) {
      final decryptedPayload = await _encryption.decrypt(r.medicalNotes);
      result.add(
        FamilyMember.fromParsedData(
          id: r.id,
          name: r.name,
          relationship: r.relationship,
          relationshipBn: r.relationshipBn,
          age: r.age,
          birthYear: r.age > 0 && r.age < 120
              ? DateTime.now().year - r.age
              : null,
          bloodGroup: r.bloodGroup,
          avatarInitials: r.avatarInitials,
          avatarColorValue: r.avatarColorValue,
          emergencyContact: r.emergencyContact,
          decryptedPayload: decryptedPayload,
        ),
      );
    }
    return result;
  }

  @override
  Future<FamilyMember?> getProfileById(String id) async {
    final row = await (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final decryptedPayload = await _encryption.decrypt(row.medicalNotes);
    return FamilyMember.fromParsedData(
      id: row.id,
      name: row.name,
      relationship: row.relationship,
      relationshipBn: row.relationshipBn,
      age: row.age,
      birthYear: row.age > 0 && row.age < 120
          ? DateTime.now().year - row.age
          : null,
      bloodGroup: row.bloodGroup,
      avatarInitials: row.avatarInitials,
      avatarColorValue: row.avatarColorValue,
      emergencyContact: row.emergencyContact,
      decryptedPayload: decryptedPayload,
    );
  }

  @override
  Future<void> saveProfile(FamilyMember profile) async {
    final payload = profile.encodeMedicalNotesPayload();
    final encryptedNotes = await _encryption.encrypt(payload);
    final now = DateTime.now().toUtc();
    final id = profile.id.isEmpty ? const Uuid().v4() : profile.id;
    final ageValue = profile.calculatedAge;

    await _db
        .into(_db.profiles)
        .insertOnConflictUpdate(
          ProfilesCompanion(
            id: Value(id),
            name: Value(profile.name),
            relationship: Value(profile.relationship),
            relationshipBn: Value(profile.relationshipBn),
            age: Value(ageValue),
            bloodGroup: Value(profile.bloodGroup),
            avatarInitials: Value(profile.avatarInitials),
            avatarColorValue: Value(profile.avatarColorValue),
            emergencyContact: Value(profile.emergencyContact),
            medicalNotes: Value(encryptedNotes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<void> deleteProfile(String id) async {
    await (_db.delete(_db.profiles)..where((p) => p.id.equals(id))).go();
  }

  @override
  Future<void> seedInitialProfilesIfEmpty(
    List<FamilyMember> defaultMembers,
  ) async {
    final count = await _db.select(_db.profiles).get();
    if (count.isEmpty) {
      for (var m in defaultMembers) {
        await saveProfile(m);
      }
    }
  }
}
