import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _defaultUrl = 'https://mwlxewrirxbhkpopslch.supabase.co';
  static const String _defaultPublishableKey =
      'sb_publishable_LTWlFrmB6eNsO96d7tT1hA_bE7HzkQO';

  static String get url =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: _defaultUrl);

  static String get publishableKey {
    const pubKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (pubKey.isNotEmpty) return pubKey;
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: _defaultPublishableKey,
    );
  }

  static String get anonKey => publishableKey;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: publishableKey,
        debug: kDebugMode,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase initialization error: $e');
      }
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
