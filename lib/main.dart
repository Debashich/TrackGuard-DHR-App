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

void main() {
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

  // Create ProviderContainer early so the UI can paint immediately
  final container = ProviderContainer();

  // Run app immediately so Flutter paints its first frame without waiting
  // for any environment, database, or network initialization.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TrackGuardApp(),
    ),
  );

  // Defer all background service initialization until AFTER the first frame is painted
  // to ensure 100% of CPU and I/O is dedicated to immediate splash dismissal.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeServices(container);
  });
}

Future<void> _initializeServices(ProviderContainer container) async {
  // Load environment variables asynchronously
  await AppEnv.load();

  if (AppEnv.hasValidSupabaseConfiguration) {
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabaseAnonKey,
      );

      final repo = container.read(authRepositoryProvider);
      if (repo is SupabaseAuthRepository) {
        repo.onSupabaseReady();
      }
    } catch (e) {
      debugPrint('Supabase initialization failed (offline): $e');
    }
  } else {
    debugPrint(
      'Supabase is not configured. Online authentication and sync are disabled.',
    );
  }

  // Start background offline AI readiness check
  try {
    container.read(aiStartupInitializerProvider).initializeOnStartup();
  } catch (e) {
    debugPrint('AI startup check notice: $e');
  }
}
