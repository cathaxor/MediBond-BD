import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/localization/app_localizations.dart';
import 'package:medibond_bd/core/localization/locale_provider.dart';
import 'package:medibond_bd/core/theme/theme_provider.dart';
import 'package:medibond_bd/data/database/app_database.dart';
import 'package:medibond_bd/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SettingsRepository settingsRepo;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    settingsRepo = DriftSettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 8 App Settings & Localization Tests', () {
    test(
      'SettingsRepository saves and retrieves preferences in SQLite',
      () async {
        await settingsRepo.saveSetting('language', 'bn');
        await settingsRepo.saveSetting('snooze_duration', '15');

        final lang = await settingsRepo.getSetting('language');
        final snooze = await settingsRepo.getSetting('snooze_duration');

        expect(lang, 'bn');
        expect(snooze, '15');
      },
    );

    test('LocaleNotifier toggles between English and Bangla', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(localeProvider), const Locale('en', ''));

      container.read(localeProvider.notifier).toggleLocale();
      expect(container.read(localeProvider), const Locale('bn', ''));

      container.read(localeProvider.notifier).toggleLocale();
      expect(container.read(localeProvider), const Locale('en', ''));
    });

    test('ThemeModeNotifier toggles theme modes correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.system);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('AppLocalizations translates keys in both English and Bangla', () {
      final locEn = AppLocalizations(const Locale('en', ''));
      final locBn = AppLocalizations(const Locale('bn', ''));

      expect(locEn.translate('appName'), 'MediBond BD');
      expect(locBn.translate('appName'), 'মেডিবন্ড বিডি');

      expect(locEn.translate('navHome'), 'Home');
      expect(locBn.translate('navHome'), 'হোম');
    });
  });
}
