import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/security/secure_encryption_service.dart';
import 'package:medibond_bd/core/security/security_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SecureEncryptionService encryptionService;

  setUp(() {
    encryptionService = SecureEncryptionService();
  });

  group('Phase 9 Security Hardening Tests', () {
    test(
      'SecurityController manages app lock and inactivity timeout correctly',
      () {
        final container = ProviderContainer();
        var secState = container.read(securityControllerProvider);

        expect(secState.isAppLockEnabled, isFalse);
        expect(secState.isLocked, isFalse);

        // Enable App Lock
        container
            .read(securityControllerProvider.notifier)
            .setAppLockEnabled(true);
        secState = container.read(securityControllerProvider);
        expect(secState.isAppLockEnabled, isTrue);

        // Set timeout to 1 minute
        container
            .read(securityControllerProvider.notifier)
            .setInactivityTimeout(1);
        secState = container.read(securityControllerProvider);
        expect(secState.inactivityTimeoutMinutes, 1);

        // Lock immediately
        container.read(securityControllerProvider.notifier).lockImmediately();
        secState = container.read(securityControllerProvider);
        expect(secState.isLocked, isTrue);

        // Unlock with PIN
        container
            .read(securityControllerProvider.notifier)
            .unlockApp(pin: '1234');
        secState = container.read(securityControllerProvider);
        expect(secState.isLocked, isFalse);
      },
    );

    test('SecureEncryptionService encrypts sensitive notes without logging raw payload', () async {
      const sensitiveText =
          'Confidential Doctor Diagnosis & Prescription Notes';
      final encrypted = await encryptionService.encrypt(sensitiveText);

      expect(encrypted.startsWith('ENC:'), isTrue);
      expect(encrypted.contains('Confidential Doctor Diagnosis'), isFalse);

      final decrypted = await encryptionService.decrypt(encrypted);
      expect(decrypted, sensitiveText);
    });
  });
}
