import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_language.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import 'auth_repository.dart';

class DevelopmentAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  DevelopmentAuthRepository() {
    _currentUser = null;
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
    if (_currentUser != null) return _currentUser;
    final client = _getSupabaseClient();
    if (client != null && client.auth.currentUser != null) {
      final supaUser = client.auth.currentUser!;
      final profile = await loadProfile(supaUser.id);
      if (profile != null) {
        _currentUser = profile;
        _controller.add(profile);
        return profile;
      }
    }
    return null;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final client = _getSupabaseClient();
    if (client != null) {
      try {
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.trackguard://login-callback/',
        );
      } catch (e) {
        debugPrint('[DevelopmentAuthRepository] Google sign-in note: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final user = AppUser(
      id: client?.auth.currentUser?.id ?? 'dhr-gangman-001',
      fullName: 'Ramesh Sharma',
      email:
          client?.auth.currentUser?.email ??
          'ramesh.sharma@dhr.railways.gov.in',
      role: UserRole.gangman,
      assignedSection: 'kurseong-ghum',
      preferredLanguage: AppLanguage.en,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signInDevelopment({
    required UserRole role,
    bool isActive = true,
  }) async {
    final client = _getSupabaseClient();
    String userId = role == UserRole.gangman
        ? 'dhr-gangman-001'
        : 'dhr-admin-001';

    if (client != null) {
      try {
        if (client.auth.currentUser == null) {
          final res = await client.auth.signInAnonymously();
          if (res.user != null) {
            userId = res.user!.id;
            debugPrint(
              '[DevelopmentAuthRepository] Signed into Supabase anonymously as $userId',
            );
          }
        } else {
          userId = client.auth.currentUser!.id;
          debugPrint(
            '[DevelopmentAuthRepository] Using active Supabase session $userId',
          );
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
          debugPrint(
            '[DevelopmentAuthRepository] Ensured profile in Supabase for $userId',
          );
        } catch (profileError) {
          debugPrint(
            '[DevelopmentAuthRepository] Note: Profile upsert error: $profileError',
          );
        }
      } catch (authError) {
        debugPrint(
          '[DevelopmentAuthRepository] Supabase anonymous sign-in not available: $authError. '
          'If you want dev users to sync to Supabase, enable Anonymous Sign-Ins in Supabase Dashboard (Auth -> Providers -> Anonymous).',
        );
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
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
    bool isSignUp = false,
  }) async {
    final client = _getSupabaseClient();
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Run with SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    final AuthResponse res;
    if (isSignUp) {
      res = await client.auth.signUp(email: email, password: password);
    } else {
      res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    }

    final supaUser = res.user;
    if (supaUser == null) {
      throw StateError('Sign-in failed: no user returned.');
    }

    AppUser? profile = await loadProfile(supaUser.id);
    if (profile == null) {
      final role = email.toLowerCase().contains('admin')
          ? UserRole.admin
          : UserRole.gangman;
      final name = email.split('@').first;
      try {
        await client.from('profiles').upsert({
          'id': supaUser.id,
          'full_name': name,
          'email': supaUser.email ?? email,
          'role': role.name,
          'assigned_section': 'kurseong-ghum',
          'preferred_language': 'en',
          'is_active': true,
        });
      } catch (e) {
        debugPrint('[DevelopmentAuthRepository] Profile creation error: $e');
      }

      profile = AppUser(
        id: supaUser.id,
        fullName: name,
        email: supaUser.email ?? email,
        role: role,
        assignedSection: 'kurseong-ghum',
        preferredLanguage: AppLanguage.en,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    _currentUser = profile;
    _controller.add(profile);
    return profile;
  }

  @override
  Future<void> signOut() async {
    final client = _getSupabaseClient();
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<AppUser?> loadProfile(String userId) async {
    final client = _getSupabaseClient();
    if (client == null) return _currentUser;

    try {
      final rows = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (rows != null) {
        return AppUser.fromJson(Map<String, dynamic>.from(rows));
      }
    } catch (_) {}

    return _currentUser;
  }
}
