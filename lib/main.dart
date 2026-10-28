import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_ANON_KEY');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );

  runApp(
    const ProviderScope(
      child: TrackGuardApp(),
    ),
  );
}