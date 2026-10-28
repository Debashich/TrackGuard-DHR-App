import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_language.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import 'auth_repository.dart';

class DevelopmentAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  DevelopmentAuthRepository() {
    final client = _getSupabaseClient();

    if (client != null) {
      client.auth.onAuthStateChange.listen((data) async {
        final supaUser = data.session?.user;

        if (supaUser == null) {
          _controller.add(null);
          return;
        }

        try {
          final profile = await loadProfile(supaUser.id);

          if (profile == null) {
            _controller.addError(ProfileNotFoundException(supaUser.id));
            return;
          }

          _controller.add(profile);
        } catch (error, stackTrace) {
          _controller.addError(error, stackTrace);
        }
      });
    }
  }

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AppUser?> watchAuthState() => _controller.stream;

  @override
  Future<AppUser?> getCurrentUser() async {
    final client = _getSupabaseClient();
    final supaUser = client?.auth.currentUser;

    if (supaUser == null) {
      return null;
    }

    final profile = await loadProfile(supaUser.id);

    if (profile == null) {
      throw ProfileNotFoundException(supaUser.id);
    }

    return profile;
  }

  @override
  Future<void> signInWithGoogle() async {
    final client = _getSupabaseClient();

    if (client == null) {
      throw StateError(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    final launched = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.trackguard://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw StateError('Could not start Google sign-in.');
    }

    // The auth-state listener handles the completed OAuth redirect.
  }

  @override
  Future<AppUser> signInDevelopment({
    required UserRole role,
    bool isActive = true,
  }) async {
    if (!kDebugMode) {
      throw StateError('Development sign-in is disabled in release builds.');
    }

    final client = _getSupabaseClient();
    var userId = role == UserRole.gangman ? 'dhr-gangman-001' : 'dhr-admin-001';

    if (client != null) {
      try {
        if (client.auth.currentUser == null) {
          final response = await client.auth.signInAnonymously();
          if (response.user != null) {
            userId = response.user!.id;
          }
        } else {
          userId = client.auth.currentUser!.id;
        }

        try {
          await client.from('profiles').upsert({
            'id': userId,
            'full_name': role == UserRole.gangman
                ? 'Ramesh Sharma'
                : 'Pradeep Thapa (SSE)',
            'email': role == UserRole.gangman
                ? 'ramesh.sharma@dhr.railways.gov.in'
                : 'pradeep.sse@dhr.railways.gov.in',
            'role': role.name,
            'assigned_section': 'kurseong-ghum',
            'preferred_language': 'en',
            'is_active': isActive,
          });
        } catch (error) {
          debugPrint('Development profile upsert failed: $error');
        }
      } catch (error) {
        debugPrint('Development Supabase sign-in failed: $error');
      }
    }

    final user = AppUser(
      id: userId,
      fullName: role == UserRole.gangman
          ? 'Ramesh Sharma'
          : 'Pradeep Thapa (SSE)',
      email: role == UserRole.gangman
          ? 'ramesh.sharma@dhr.railways.gov.in'
          : 'pradeep.sse@dhr.railways.gov.in',
      role: role,
      assignedSection: 'kurseong-ghum',
      preferredLanguage: AppLanguage.en,
      isActive: isActive,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    final client = _getSupabaseClient();

    if (client != null && client.auth.currentSession != null) {
      await client.auth.signOut();
    }

    _controller.add(null);
  }

  @override
  Future<AppUser?> loadProfile(String userId) async {
    final client = _getSupabaseClient();

    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    final row = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;

    return AppUser.fromJson(Map<String, dynamic>.from(row));
  }
}
