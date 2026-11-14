import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/family_member.dart';
import '../data/models/medication_log.dart';
import '../data/models/medicine.dart';
import '../data/models/prescription.dart';
import '../data/providers/database_providers.dart';
import '../data/repositories/dose_event_repository.dart';
import '../data/repositories/medicine_repository.dart';
import '../data/repositories/prescription_repository.dart';
import '../data/repositories/profile_repository.dart';

class AppStateData {
  final List<FamilyMember> members;
  final List<Medicine> medicines;
  final List<MedicationLog> logs;
  final List<Prescription> prescriptions;
  final String selectedFamilyMemberId;
  final bool isLoading;

  AppStateData({
    required this.members,
    required this.medicines,
    required this.logs,
    required this.prescriptions,
    required this.selectedFamilyMemberId,
    this.isLoading = false,
  });

  /// Returns the primary profile (relationship == 'Self' or first member)
  FamilyMember? get primaryProfile {
    if (members.isEmpty) return null;
    try {
      return members.firstWhere(
        (m) => m.relationship == 'Self',
        orElse: () => members.first,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns true if a valid primary profile exists
  bool get hasPrimaryProfile =>
      members.any(
        (m) => m.relationship == 'Self' && m.name.trim().isNotEmpty,
      ) ||
      (members.isNotEmpty && members.first.name.trim().isNotEmpty);

  /// Returns the name of the primary user
  String get primaryUserName => primaryProfile?.name ?? '';

  /// Returns the currently active profile based on selectedFamilyMemberId filter
  FamilyMember? get activeProfile {
    if (members.isEmpty) return null;
    if (selectedFamilyMemberId == 'all') {
      return primaryProfile;
    }
    try {
      return members.firstWhere(
        (m) => m.id == selectedFamilyMemberId,
        orElse: () => primaryProfile ?? members.first,
      );
    } catch (_) {
      return primaryProfile;
    }
  }

  /// Returns the display name for the active profile greeting
  String get activeUserName => activeProfile?.name ?? primaryUserName;

  AppStateData copyWith({
    List<FamilyMember>? members,
    List<Medicine>? medicines,
    List<MedicationLog>? logs,
    List<Prescription>? prescriptions,
    String? selectedFamilyMemberId,
    bool? isLoading,
  }) {
    return AppStateData(
      members: members ?? this.members,
      medicines: medicines ?? this.medicines,
      logs: logs ?? this.logs,
      prescriptions: prescriptions ?? this.prescriptions,
      selectedFamilyMemberId:
          selectedFamilyMemberId ?? this.selectedFamilyMemberId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppStateData> {
  final ProfileRepository profileRepo;
  final MedicineRepository medicineRepo;
  final DoseEventRepository doseEventRepo;
  final PrescriptionRepository prescriptionRepo;

  AppStateNotifier({
    required this.profileRepo,
    required this.medicineRepo,
    required this.doseEventRepo,
    required this.prescriptionRepo,
  }) : super(
         AppStateData(
           members: [],
           medicines: [],
           logs: [],
           prescriptions: [],
           selectedFamilyMemberId: 'all',
           isLoading: true,
         ),
       ) {
    initDatabase();
  }

  Future<void> initDatabase() async {
    state = state.copyWith(isLoading: true);
    await cleanupLegacyDemoData();
    await loadFromDatabase();
  }

  Future<void> cleanupLegacyDemoData() async {
    const seedMemberIds = {'m1', 'm2', 'm3', 'm4', 'm5'};
    const seedMedIds = {'med1', 'med2', 'med3', 'med4', 'med5'};
    const seedLogIds = {
      'log1',
      'log2',
      'log3',
      'log4',
      'log5',
      'log6',
      'log7',
      'log8',
      'log9',
    };
    const seedRxIds = {'pres1', 'pres2', 'pres3'};

    final existingMembers = await profileRepo.getAllProfiles();
    for (var m in existingMembers) {
      if (seedMemberIds.contains(m.id)) {
        await profileRepo.deleteProfile(m.id);
      }
    }

    final existingMeds = await medicineRepo.getAllMedicines();
    for (var med in existingMeds) {
      if (seedMedIds.contains(med.id) ||
          seedMemberIds.contains(med.familyMemberId)) {
        await medicineRepo.deleteMedicine(med.id);
      }
    }

    final existingLogs = await doseEventRepo.getAllLogs();
    for (var log in existingLogs) {
      if (seedLogIds.contains(log.id) ||
          seedMemberIds.contains(log.familyMemberId)) {
        await doseEventRepo.deleteLog(log.id);
      }
    }

    final existingRx = await prescriptionRepo.getAllPrescriptions();
    for (var rx in existingRx) {
      if (seedRxIds.contains(rx.id) ||
          seedMemberIds.contains(rx.familyMemberId)) {
        await prescriptionRepo.deletePrescription(rx.id);
      }
    }
  }

  Future<void> loadFromDatabase() async {
    final results = await Future.wait([
      profileRepo.getAllProfiles(),
      medicineRepo.getAllMedicines(),
      doseEventRepo.getAllLogs(),
      prescriptionRepo.getAllPrescriptions(),
    ]);

    state = state.copyWith(
      members: results[0] as List<FamilyMember>,
      medicines: results[1] as List<Medicine>,
      logs: results[2] as List<MedicationLog>,
      prescriptions: results[3] as List<Prescription>,
      isLoading: false,
    );
  }

  void selectFamilyMember(String id) {
    state = state.copyWith(selectedFamilyMemberId: id);
  }

  Future<void> savePrimaryProfile(FamilyMember profile) async {
    final existingSelf = state.members.cast<FamilyMember?>().firstWhere(
      (m) => m?.relationship == 'Self',
      orElse: () => null,
    );

    final targetId =
        existingSelf?.id ??
        (profile.id.isNotEmpty ? profile.id : 'primary_self');

    final updatedProfile = profile.copyWith(id: targetId, relationship: 'Self');
    await profileRepo.saveProfile(updatedProfile);
    await loadFromDatabase();
    selectFamilyMember(targetId);
  }

  Future<void> addFamilyMember(FamilyMember member) async {
    if (member.relationship == 'Self') {
      await savePrimaryProfile(member);
      return;
    }
    await profileRepo.saveProfile(member);
    await loadFromDatabase();
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    await profileRepo.saveProfile(member);
    await loadFromDatabase();
  }

  Future<void> resetToDemoData() async {
    await clearAllUserData();
  }

  Future<void> clearAllUserData() async {
    state = state.copyWith(isLoading: true);
    for (var m in state.members) {
      await profileRepo.deleteProfile(m.id);
    }
    for (var med in state.medicines) {
      await medicineRepo.deleteMedicine(med.id);
    }
    for (var rx in state.prescriptions) {
      await prescriptionRepo.deletePrescription(rx.id);
    }
    await loadFromDatabase();
  }

  Future<void> markLogStatus(String logId, MedicationLogStatus status) async {
    final actionAt = status == MedicationLogStatus.taken
        ? DateTime.now()
        : null;
    await doseEventRepo.updateLogStatus(logId, status, actionAt);

    if (status == MedicationLogStatus.taken) {
      final log = state.logs.firstWhere((l) => l.id == logId);
      final med = state.medicines.firstWhere((m) => m.id == log.medicineId);
      if (med.stockCount > 0) {
        final updatedMed = med.copyWith(stockCount: med.stockCount - 1);
        await medicineRepo.saveMedicine(updatedMed);
      }
    }

    await loadFromDatabase();
  }

  Future<void> saveMedicine(Medicine med) async {
    await medicineRepo.saveMedicine(med);

    final now = DateTime.now();
    for (var time in med.scheduledTimes) {
      final scheduledDT = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      final newLog = MedicationLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}_${time.hour}',
        medicineId: med.id,
        medicineName: med.name,
        familyMemberId: med.familyMemberId,
        dosage: med.dosage,
        form: med.form,
        instructions: med.instructions,
        scheduledDateTime: scheduledDT,
        status: MedicationLogStatus.pending,
      );
      await doseEventRepo.saveLog(newLog);
    }

    await loadFromDatabase();
  }

  Future<void> togglePauseMedicine(String id) async {
    final med = state.medicines.firstWhere((m) => m.id == id);
    await medicineRepo.togglePauseMedicine(id, !med.isPaused);
    await loadFromDatabase();
  }

  Future<void> toggleArchiveMedicine(String id) async {
    final med = state.medicines.firstWhere((m) => m.id == id);
    await medicineRepo.toggleArchiveMedicine(id, !med.isActive);
    await loadFromDatabase();
  }

  Future<void> deleteMedicine(String id) async {
    await medicineRepo.deleteMedicine(id);
    await loadFromDatabase();
  }

  Future<void> addPrescription(
    Prescription rx, {
    Uint8List? documentBytes,
  }) async {
    await prescriptionRepo.savePrescription(
      rx,
      rawDocumentBytes: documentBytes,
    );
    await loadFromDatabase();
  }

  Future<void> updatePrescriptionTitle(String id, String newTitle) async {
    await prescriptionRepo.updatePrescriptionTitle(id, newTitle);
    await loadFromDatabase();
  }

  Future<void> deletePrescription(String id) async {
    await prescriptionRepo.deletePrescription(id);
    await loadFromDatabase();
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppStateData>((
  ref,
) {
  return AppStateNotifier(
    profileRepo: ref.watch(profileRepositoryProvider),
    medicineRepo: ref.watch(medicineRepositoryProvider),
    doseEventRepo: ref.watch(doseEventRepositoryProvider),
    prescriptionRepo: ref.watch(prescriptionRepositoryProvider),
  );
});

final selectedMemberIdProvider = Provider<String>((ref) {
  return ref.watch(appStateProvider).selectedFamilyMemberId;
});

final filteredMedicinesProvider = Provider<List<Medicine>>((ref) {
  final appState = ref.watch(appStateProvider);
  if (appState.selectedFamilyMemberId == 'all') {
    return appState.medicines;
  }
  return appState.medicines
      .where((m) => m.familyMemberId == appState.selectedFamilyMemberId)
      .toList();
});

final filteredLogsProvider = Provider<List<MedicationLog>>((ref) {
  final appState = ref.watch(appStateProvider);
  if (appState.selectedFamilyMemberId == 'all') {
    return appState.logs;
  }
  return appState.logs
      .where((l) => l.familyMemberId == appState.selectedFamilyMemberId)
      .toList();
});

final nextPendingLogProvider = Provider<MedicationLog?>((ref) {
  final logs = ref.watch(filteredLogsProvider);
  final pending = logs
      .where((l) => l.status == MedicationLogStatus.pending)
      .toList();
  if (pending.isEmpty) return null;
  pending.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  return pending.first;
});
