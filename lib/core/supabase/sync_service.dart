import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/database_providers.dart';
import '../../data/repositories/dose_event_repository.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../data/repositories/profile_repository.dart';
import 'app_release_service.dart';
import 'supabase_config.dart';

enum SyncStatus { idle, syncing, synced, offline, error }

class SyncState {
  final SyncStatus status;
  final String? message;
  final DateTime? lastSyncedAt;

  SyncState({this.status = SyncStatus.idle, this.message, this.lastSyncedAt});

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSyncedAt,
  }) {
    return SyncState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class SyncService extends StateNotifier<SyncState> {
  final ProfileRepository profileRepo;
  final MedicineRepository medicineRepo;
  final DoseEventRepository doseEventRepo;
  final PrescriptionRepository prescriptionRepo;
  final Ref ref;

  SyncService({
    required this.profileRepo,
    required this.medicineRepo,
    required this.doseEventRepo,
    required this.prescriptionRepo,
    required this.ref,
  }) : super(SyncState());

  Future<void> syncAll() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        status: SyncStatus.offline,
        message: 'Operating 100% offline. Health data is encrypted locally.',
      );
      return;
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      message: 'Checking application release configuration...',
    );

    try {
      // Perform non-sensitive app release & update checks
      await ref.read(appReleaseProvider.notifier).checkForUpdates();

      state = state.copyWith(
        status: SyncStatus.synced,
        message: 'Account active. Health records remain 100% private offline.',
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('App release check exception: $e');
      }
      state = state.copyWith(
        status: SyncStatus.offline,
        message: 'Operating offline. Health data encrypted on device.',
      );
    }
  }
}

final syncServiceProvider = StateNotifierProvider<SyncService, SyncState>((
  ref,
) {
  return SyncService(
    profileRepo: ref.watch(profileRepositoryProvider),
    medicineRepo: ref.watch(medicineRepositoryProvider),
    doseEventRepo: ref.watch(doseEventRepositoryProvider),
    prescriptionRepo: ref.watch(prescriptionRepositoryProvider),
    ref: ref,
  );
});
