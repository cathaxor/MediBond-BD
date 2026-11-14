import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';

enum AppAccentColor {
  teal(AppColors.primary, 'MediBond Teal'),
  blue(Color(0xFF1E40AF), 'Ocean Blue'),
  green(Color(0xFF047857), 'Emerald Green'),
  purple(Color(0xFF7C3AED), 'Royal Purple'),
  rose(Color(0xFF9D174D), 'Rose'),
  amber(Color(0xFFD97706), 'Amber');

  final Color color;
  final String displayName;
  const AppAccentColor(this.color, this.displayName);
}

class ThemeSettingsState {
  final ThemeMode themeMode;
  final AppAccentColor accentColor;

  const ThemeSettingsState({
    this.themeMode = ThemeMode.system,
    this.accentColor = AppAccentColor.teal,
  });

  ThemeSettingsState copyWith({
    ThemeMode? themeMode,
    AppAccentColor? accentColor,
  }) {
    return ThemeSettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettingsState> {
  ThemeSettingsNotifier() : super(const ThemeSettingsState()) {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('app_theme_mode') ?? 2; // Default system
      final accentIndex = prefs.getInt('app_accent_color') ?? 0; // Default teal

      final mode =
          ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)];
      final accent = AppAccentColor
          .values[accentIndex.clamp(0, AppAccentColor.values.length - 1)];

      state = ThemeSettingsState(themeMode: mode, accentColor: accent);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_theme_mode', mode.index);
    } catch (_) {}
  }

  Future<void> setAccentColor(AppAccentColor color) async {
    state = state.copyWith(accentColor: color);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_accent_color', color.index);
    } catch (_) {}
  }
}

final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettingsState>((ref) {
      return ThemeSettingsNotifier();
    });

class LegacyThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;
  LegacyThemeModeNotifier(this.ref)
    : super(ref.read(themeSettingsProvider).themeMode);

  void setThemeMode(ThemeMode mode) {
    ref.read(themeSettingsProvider.notifier).setThemeMode(mode);
    state = mode;
  }

  void toggleTheme() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(next);
  }
}

// Backward-compatible themeModeProvider
final themeModeProvider =
    StateNotifierProvider<LegacyThemeModeNotifier, ThemeMode>((ref) {
      return LegacyThemeModeNotifier(ref);
    });
