import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/config/app_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppEnv Tests', () {
    test('Defaults provide valid Supabase configuration', () {
      expect(AppEnv.supabaseUrl, isNotEmpty);
      expect(AppEnv.supabaseUrl, startsWith('https://'));
      expect(AppEnv.supabaseAnonKey, isNotEmpty);
      expect(AppEnv.hasValidSupabaseConfiguration, isTrue);
    });

    test('get returns defaultValue when key is missing and env not loaded', () {
      final val = AppEnv.get('NON_EXISTENT_KEY_123', defaultValue: 'fallback');
      expect(val, equals('fallback'));
    });
  });
}

