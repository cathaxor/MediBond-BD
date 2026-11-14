import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_config.dart';

class AppRelease {
  final String id;
  final String platform;
  final String channel;
  final String versionName;
  final int buildNumber;
  final int minimumSupportedBuild;
  final String releaseNotes;
  final String updateUrl;
  final bool isActive;
  final DateTime? publishedAt;

  const AppRelease({
    required this.id,
    required this.platform,
    required this.channel,
    required this.versionName,
    required this.buildNumber,
    required this.minimumSupportedBuild,
    required this.releaseNotes,
    required this.updateUrl,
    this.isActive = true,
    this.publishedAt,
  });

  factory AppRelease.fromMap(Map<String, dynamic> map) {
    return AppRelease(
      id: map['id']?.toString() ?? '',
      platform: map['platform']?.toString() ?? 'android',
      channel: map['channel']?.toString() ?? 'production',
      versionName:
          map['version_name']?.toString() ??
          map['version']?.toString() ??
          '1.0.0',
      buildNumber: (map['build_number'] as num?)?.toInt() ?? 1,
      minimumSupportedBuild:
          (map['minimum_supported_build'] as num?)?.toInt() ?? 1,
      releaseNotes:
          map['release_notes']?.toString() ??
          map['update_message']?.toString() ??
          '',
      updateUrl:
          map['update_url']?.toString() ?? map['store_url']?.toString() ?? '',
      isActive: map['is_active'] as bool? ?? true,
      publishedAt: map['published_at'] != null
          ? DateTime.tryParse(map['published_at'].toString())
          : null,
    );
  }

  bool get isUrlValid {
    if (updateUrl.isEmpty) return false;
    final uri = Uri.tryParse(updateUrl);
    if (uri == null) return false;
    return uri.scheme == 'https' || uri.scheme == 'market';
  }
}

class AppReleaseState {
  final bool isLoading;
  final String currentVersion;
  final int currentBuild;
  final AppRelease? latestRelease;
  final bool isUpdateAvailable;
  final bool isMandatoryUpdate;
  final DateTime? lastCheckTime;
  final String? errorMessage;
  final bool hasShownDialog;

  AppReleaseState({
    this.isLoading = false,
    this.currentVersion = '1.0.0',
    this.currentBuild = 1,
    this.latestRelease,
    this.isUpdateAvailable = false,
    this.isMandatoryUpdate = false,
    this.lastCheckTime,
    this.errorMessage,
    this.hasShownDialog = false,
  });

  AppReleaseState copyWith({
    bool? isLoading,
    String? currentVersion,
    int? currentBuild,
    AppRelease? latestRelease,
    bool? isUpdateAvailable,
    bool? isMandatoryUpdate,
    DateTime? lastCheckTime,
    String? errorMessage,
    bool? hasShownDialog,
  }) {
    return AppReleaseState(
      isLoading: isLoading ?? this.isLoading,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuild: currentBuild ?? this.currentBuild,
      latestRelease: latestRelease ?? this.latestRelease,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      isMandatoryUpdate: isMandatoryUpdate ?? this.isMandatoryUpdate,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      errorMessage: errorMessage ?? this.errorMessage,
      hasShownDialog: hasShownDialog ?? this.hasShownDialog,
    );
  }
}

class AppReleaseController extends StateNotifier<AppReleaseState> {
  static const Duration throttleDuration = Duration(hours: 1);

  AppReleaseController() : super(AppReleaseState()) {
    _initLocalInfo();
  }

  Future<void> _initLocalInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final installedBuild = int.tryParse(info.buildNumber) ?? 1;
      state = state.copyWith(
        currentVersion: info.version.isNotEmpty ? info.version : '1.0.0',
        currentBuild: installedBuild,
      );
    } catch (_) {
      // Fallback for widget test environment
      state = state.copyWith(currentVersion: '1.0.0', currentBuild: 1);
    }
  }

  void markDialogShown() {
    state = state.copyWith(hasShownDialog: true);
  }

  Future<void> checkForUpdates({
    bool isManual = false,
    int? mockCurrentBuild,
  }) async {
    final now = DateTime.now();

    // Throttling for foreground auto checks
    if (!isManual &&
        state.lastCheckTime != null &&
        now.difference(state.lastCheckTime!) < throttleDuration) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      int installedBuild = mockCurrentBuild ?? state.currentBuild;
      if (mockCurrentBuild == null) {
        try {
          final info = await PackageInfo.fromPlatform();
          installedBuild = int.tryParse(info.buildNumber) ?? installedBuild;
        } catch (_) {}
      }

      final response = await SupabaseConfig.client
          .from('app_releases')
          .select()
          .eq('platform', 'android')
          .eq('channel', 'production')
          .eq('is_active', true)
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (response == null) {
        state = state.copyWith(
          isLoading: false,
          isUpdateAvailable: false,
          isMandatoryUpdate: false,
          lastCheckTime: now,
        );
        _cacheLastCheck(now);
        return;
      }

      final release = AppRelease.fromMap(response);

      if (!release.isUrlValid) {
        state = state.copyWith(
          isLoading: false,
          isUpdateAvailable: false,
          isMandatoryUpdate: false,
          lastCheckTime: now,
          errorMessage: 'Invalid update URL in release configuration.',
        );
        return;
      }

      final updateAvail = release.buildNumber > installedBuild;
      final mandatory = release.minimumSupportedBuild > installedBuild;

      state = state.copyWith(
        isLoading: false,
        currentBuild: installedBuild,
        latestRelease: release,
        isUpdateAvailable: updateAvail,
        isMandatoryUpdate: mandatory,
        lastCheckTime: now,
        hasShownDialog: false, // Reset dialog flag when new check runs
      );

      _cacheLastCheck(now);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('App release check exception/offline fallback: $e');
      }
      state = state.copyWith(
        isLoading: false,
        lastCheckTime: now,
        errorMessage: isManual ? 'Unable to connect to release server.' : null,
      );
    }
  }

  Future<void> _cacheLastCheck(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_release_check', time.toIso8601String());
    } catch (_) {}
  }
}

final appReleaseProvider =
    StateNotifierProvider<AppReleaseController, AppReleaseState>((ref) {
      return AppReleaseController();
    });
