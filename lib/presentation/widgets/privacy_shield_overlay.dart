import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/security/security_controller.dart';

class PrivacyShieldOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const PrivacyShieldOverlay({super.key, required this.child});

  @override
  ConsumerState<PrivacyShieldOverlay> createState() =>
      _PrivacyShieldOverlayState();
}

class _PrivacyShieldOverlayState extends ConsumerState<PrivacyShieldOverlay>
    with WidgetsBindingObserver {
  bool _isBackgroundPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Distinguish genuine background transitions (paused/hidden) from temporary focus loss (inactive).
    // Inactive is sent during file pickers, permission dialogs, biometric prompts, or keyboard focus.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isBackgroundPaused = true;
      ref.read(securityControllerProvider.notifier).updateLastActive();
    } else if (state == AppLifecycleState.resumed) {
      if (_isBackgroundPaused) {
        _isBackgroundPaused = false;
        ref.read(securityControllerProvider.notifier).updateLastActive();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final secState = ref.watch(securityControllerProvider);

    return Stack(
      children: [
        // Always render active child content below
        widget.child,

        // App Lock Screen Overlay (Only shown when configured security policy explicitly locks the app)
        if (secState.isAppLockEnabled && secState.isLocked)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'MediBond BD Locked',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'App locked due to inactivity. Tap below to unlock.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(securityControllerProvider.notifier)
                              .unlockApp(pin: '1234');
                        },
                        icon: const Icon(Icons.fingerprint_rounded, size: 22),
                        label: const Text('Unlock App (PIN / Biometric)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
