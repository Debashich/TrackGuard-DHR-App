import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool _hasValidSupabaseConfiguration() {
  final value = _supabaseUrl.trim();
  final uri = Uri.tryParse(value);

  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      _supabasePublishableKey.trim().isNotEmpty;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_hasValidSupabaseConfiguration()) {
    await Supabase.initialize(
      url: _supabaseUrl.trim(),
      publishableKey: _supabasePublishableKey.trim(),
    );
  } else {
    debugPrint(
      'Supabase is not configured. Online authentication and sync are disabled.',
    );
  }

  runApp(const ProviderScope(child: TrackGuardApp()));
}
