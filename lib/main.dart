import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_env.dart';
import 'features/ai/application/ai_startup_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation bar and status bar colors to match the app theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF4F6F8), // AppTheme.backgroundDark
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Suppress unhandled non-fatal network exceptions (such as offline Supabase token refresh)
  PlatformDispatcher.instance.onError = (error, stack) {
    final errStr = error.toString();
    if (errStr.contains('AuthRetryableFetchException') ||
        errStr.contains('ClientException') ||
        errStr.contains('SocketException')) {
      debugPrint('Suppressed offline network exception: $errStr');
      return true;
    }
    return false;
  };

  // Load .env configuration (Next.js style)
  await AppEnv.load();

  if (AppEnv.hasValidSupabaseConfiguration) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabaseAnonKey,
    );
  } else {
    debugPrint(
      'Supabase is not configured. Online authentication and sync are disabled.',
    );
  }

  // Create ProviderContainer to trigger non-blocking startup services
  final container = ProviderContainer();

  // Start background offline AI readiness check and automatic activation
  container.read(aiStartupInitializerProvider).initializeOnStartup();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TrackGuardApp(),
    ),
  );
}
