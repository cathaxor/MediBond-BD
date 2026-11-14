import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/supabase/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SupabaseConfig provides valid configuration defaults', () {
    expect(SupabaseConfig.url, 'https://mwlxewrirxbhkpopslch.supabase.co');
    expect(
      SupabaseConfig.anonKey,
      'sb_publishable_LTWlFrmB6eNsO96d7tT1hA_bE7HzkQO',
    );
  });
}
