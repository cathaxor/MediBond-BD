import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityState {
  final bool isAppLockEnabled;
  final bool isLocked;
  final int inactivityTimeoutMinutes;
  final DateTime lastActiveTime;

  SecurityState({
    required this.isAppLockEnabled,
    required this.isLocked,
    required this.inactivityTimeoutMinutes,
    required this.lastActiveTime,
  });

  SecurityState copyWith({
    bool? isAppLockEnabled,
    bool? isLocked,
    int? inactivityTimeoutMinutes,
    DateTime? lastActiveTime,
  }) {
    return SecurityState(
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isLocked: isLocked ?? this.isLocked,
      inactivityTimeoutMinutes:
          inactivityTimeoutMinutes ?? this.inactivityTimeoutMinutes,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
    );
  }
}

class SecurityController extends StateNotifier<SecurityState> {
  SecurityController()
    : super(
        SecurityState(
          isAppLockEnabled: false,
          isLocked: false,
          inactivityTimeoutMinutes: 5,
          lastActiveTime: DateTime.now(),
        ),
      );

  void setAppLockEnabled(bool enabled) {
    state = state.copyWith(
      isAppLockEnabled: enabled,
      isLocked: enabled ? state.isLocked : false,
    );
  }

  void setInactivityTimeout(int minutes) {
    state = state.copyWith(inactivityTimeoutMinutes: minutes);
  }

  void updateLastActive() {
    final now = DateTime.now();
    if (state.isAppLockEnabled && !state.isLocked) {
      final elapsed = now.difference(state.lastActiveTime).inMinutes;
      if (elapsed >= state.inactivityTimeoutMinutes) {
        state = state.copyWith(isLocked: true);
        return;
      }
    }
    state = state.copyWith(lastActiveTime: now);
  }

  Future<bool> unlockApp({String? pin}) async {
    if (pin == null || pin == '1234' || pin.isEmpty) {
      state = state.copyWith(isLocked: false, lastActiveTime: DateTime.now());
      return true;
    }
    return false;
  }

  void lockImmediately() {
    if (state.isAppLockEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }
}

final securityControllerProvider =
    StateNotifierProvider<SecurityController, SecurityState>((ref) {
      return SecurityController();
    });
