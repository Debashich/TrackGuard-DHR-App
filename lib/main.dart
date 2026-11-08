import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_env.dart';
import 'features/ai/application/ai_startup_initializer.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge: transparent system bars everywhere
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
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

  // Load .env configuration — fast local asset read, must complete before
  // Supabase.initialize() because it provides the URL and key.
  await AppEnv.load();

  // Create ProviderContainer early so the UI can paint immediately
  final container = ProviderContainer();

  // Initialize Supabase without blocking the first frame.
  // The auth controller already handles the initializing → authenticated
  // transition, so painting the sign-in screen while Supabase boots is safe.
  if (AppEnv.hasValidSupabaseConfiguration) {
    // Fire-and-forget; the auth listener picks up the session once ready
    Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabaseAnonKey,
    ).then((_) {
      // Notify the auth repository that Supabase is now available so it
      // can attach its onAuthStateChange listener and restore the session
      final repo = container.read(authRepositoryProvider);
      if (repo is SupabaseAuthRepository) {
        repo.onSupabaseReady();
      }
      // Start AI readiness check
      container.read(aiStartupInitializerProvider).initializeOnStartup();
    }).catchError((Object e) {
      debugPrint('Supabase initialization failed (offline): $e');
      // AI startup still works offline
      container.read(aiStartupInitializerProvider).initializeOnStartup();
    });
  } else {
    debugPrint(
      'Supabase is not configured. Online authentication and sync are disabled.',
    );
    // Start background offline AI readiness check immediately
    container.read(aiStartupInitializerProvider).initializeOnStartup();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TrackGuardApp(),
    ),
  );
}
