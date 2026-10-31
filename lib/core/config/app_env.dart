import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppEnv {
  static final Map<String, String> _env = {};
  static bool _isLoaded = false;

  /// Loads environment variables from the `.env` asset file.
  /// Safely succeeds even if `.env` is absent or unreadable.
  static Future<void> load({String fileName = '.env'}) async {
    if (_isLoaded) return;
    try {
      final content = await rootBundle.loadString(fileName);
      final lines = content.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eqIdx = trimmed.indexOf('=');
        if (eqIdx == -1) continue;
        final key = trimmed.substring(0, eqIdx).trim();
        var val = trimmed.substring(eqIdx + 1).trim();
        // Remove surrounding quotes if present
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          val = val.substring(1, val.length - 1);
        }
        if (key.isNotEmpty) {
          _env[key] = val;
        }
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Notice: .env file asset not loaded: $e');
    }
  }

  /// Sets an environment variable for testing or programmatic injection.
  @visibleForTesting
  static void setForTesting(String key, String value) {
    _env[key] = value;
  }

  /// Clears test/loaded environment configuration.
  @visibleForTesting
  static void resetForTesting() {
    _env.clear();
    _isLoaded = false;
  }

  /// Retrieves a configuration value by priority:
  /// 1. `--dart-define` flag (compile-time override)
  /// 2. `.env` asset file (runtime Next.js style)
  /// 3. Built-in default value
  static String get(String key, {String defaultValue = ''}) {
    // 1. Check compile-time environment
    final dartDefineVal = String.fromEnvironment(key);
    if (dartDefineVal.isNotEmpty) {
      return dartDefineVal;
    }

    // 2. Check loaded .env file
    final envVal = _env[key];
    if (envVal != null && envVal.isNotEmpty) {
      return envVal;
    }

    return defaultValue;
  }

  /// Supabase project URL (loaded from .env)
  static String get supabaseUrl => get('SUPABASE_URL');

  /// Supabase anonymous public publishable key (loaded from .env)
  static String get supabaseAnonKey => get('SUPABASE_ANON_KEY');

  /// Checks whether valid Supabase configuration is present.
  static bool get hasValidSupabaseConfiguration {
    final url = supabaseUrl.trim();
    final key = supabaseAnonKey.trim();
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        key.isNotEmpty;
  }

  /// OpenRouter API Key for online multimodal AI inference (loaded from .env)
  static String get openRouterApiKey => get('OPENROUTER_API_KEY');

  /// OpenRouter Model (default: nvidia/nemotron-3.5-super-vl:free)
  static String get openRouterModel =>
      get('OPENROUTER_MODEL', defaultValue: 'nvidia/nemotron-3.5-super-vl:free');

  /// Checks whether valid OpenRouter configuration is present.
  static bool get hasValidOpenRouterConfiguration =>
      openRouterApiKey.trim().isNotEmpty;
}
