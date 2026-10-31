import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/config/app_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppEnv Tests', () {
    setUp(() {
      AppEnv.resetForTesting();
    });

    test('get returns defaultValue when key is missing and env not loaded', () {
      final val = AppEnv.get('NON_EXISTENT_KEY_123', defaultValue: 'fallback');
      expect(val, equals('fallback'));
    });

    test('Loads and verifies environment configuration without hardcoded secrets', () {
      expect(AppEnv.hasValidSupabaseConfiguration, isFalse);
      expect(AppEnv.hasValidOpenRouterConfiguration, isFalse);

      AppEnv.setForTesting('SUPABASE_URL', 'https://test-project.supabase.co');
      AppEnv.setForTesting('SUPABASE_ANON_KEY', 'test-anon-key');
      AppEnv.setForTesting('OPENROUTER_API_KEY', 'test-openrouter-key');

      expect(AppEnv.supabaseUrl, equals('https://test-project.supabase.co'));
      expect(AppEnv.supabaseAnonKey, equals('test-anon-key'));
      expect(AppEnv.hasValidSupabaseConfiguration, isTrue);
      expect(AppEnv.openRouterApiKey, equals('test-openrouter-key'));
      expect(AppEnv.hasValidOpenRouterConfiguration, isTrue);
      expect(AppEnv.openRouterModel, equals('nvidia/nemotron-3.5-super-vl:free'));
    });
  });
}
