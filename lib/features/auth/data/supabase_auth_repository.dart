import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_language.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  static const _cachedUserKey = 'trackguard_cached_user_profile_v1';
  final _controller = StreamController<AppUser?>.broadcast();

  SupabaseAuthRepository() {
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
        } catch (error) {
          debugPrint('Auth state change profile fetch failed (offline fallback): $error');
          final cached = await getCachedUser();
          if (cached != null) {
            _controller.add(cached);
          } else {
            final fallback = _createFallbackUser(
              id: supaUser.id,
              email: supaUser.email,
            );
            await cacheUser(fallback);
            _controller.add(fallback);
          }
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

  Future<void> cacheUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Failed to cache user profile: $e');
    }
  }

  @override
  Future<AppUser?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedUserKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return AppUser.fromJson(map);
      }
    } catch (e) {
      debugPrint('Failed to load cached user profile: $e');
    }
    return null;
  }

  Future<void> clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
    } catch (e) {
      debugPrint('Failed to clear cached user profile: $e');
    }
  }

  AppUser _createFallbackUser({
    required String id,
    String? email,
    String? fullName,
    UserRole role = UserRole.gangman,
    String assignedSection = 'kurseong-ghum',
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? (role == UserRole.gangman ? 'Gangman' : 'Supervisor'),
      email: email ?? '',
      role: role,
      assignedSection: assignedSection,
      preferredLanguage: AppLanguage.en,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Stream<AppUser?> watchAuthState() => _controller.stream;

  @override
  Future<AppUser?> getCurrentUser() async {
    // 1. Immediately check cached profile for fast offline access
    final cached = await getCachedUser();

    final client = _getSupabaseClient();
    final supaUser = client?.auth.currentUser;

    if (supaUser == null) {
      return cached;
    }

    try {
      final profile = await loadProfile(supaUser.id);
      if (profile != null) {
        await cacheUser(profile);
        return profile;
      }
    } catch (error) {
      debugPrint('getCurrentUser: remote loadProfile failed (offline): $error');
    }

    if (cached != null) {
      return cached;
    }

    // Offline session exists in Supabase without cached profile; create durable offline user
    final fallback = _createFallbackUser(
      id: supaUser.id,
      email: supaUser.email,
    );
    await cacheUser(fallback);
    return fallback;
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
  }

  @override
  Future<void> signOut() async {
    final client = _getSupabaseClient();

    if (client != null && client.auth.currentSession != null) {
      try {
        await client.auth.signOut();
      } catch (error) {
        debugPrint('Supabase sign-out failed (offline): $error');
      }
    }

    await clearCachedUser();
    _controller.add(null);
  }

  @override
  Future<AppUser?> loadProfile(String userId) async {
    final client = _getSupabaseClient();

    if (client == null) {
      return await getCachedUser();
    }

    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (row == null) return null;

      final user = AppUser.fromJson(Map<String, dynamic>.from(row));
      await cacheUser(user);
      return user;
    } catch (error) {
      debugPrint('loadProfile failed (offline or network error): $error');
      final cached = await getCachedUser();
      if (cached != null) return cached;
      rethrow;
    }
  }
}

