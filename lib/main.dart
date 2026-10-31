import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_env.dart';
import 'features/ai/application/ai_startup_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
