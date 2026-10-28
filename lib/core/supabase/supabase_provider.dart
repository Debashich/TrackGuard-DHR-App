import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    return null;
  }

  return Supabase.instance.client;
});