import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return _sharedAuthRepo;
});

final _sharedAuthRepo = SupabaseAuthRepository();

class AuthController extends Notifier<AuthState> {
  late AuthRepository _repository;
  StreamSubscription<AppUser?>? _authSubscription;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);

    _authSubscription = _repository.watchAuthState().listen(
      (user) {
        if (user == null) {
          state = AuthState.unauthenticated();
        } else {
          _handleUserLoaded(user);
        }
      },
      onError: (Object error) {
        if (error is ProfileNotFoundException) {
          state = AuthState.profilePending();
        } else {
          debugPrint('Auth subscription error: $error; attempting cached fallback.');
          _tryFallbackToCached();
        }
      },
    );

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    _restoreSession();

    return AuthState.unauthenticated();
  }

  Future<void> _tryFallbackToCached() async {
    final cached = await _repository.getCachedUser();
    if (cached != null) {
      _handleUserLoaded(cached);
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> _restoreSession() async {
    try {
      final user = await _repository.getCurrentUser();

      if (user != null) {
        _handleUserLoaded(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } on ProfileNotFoundException {
      state = AuthState.profilePending();
    } catch (error) {
      debugPrint('Restore session caught error: $error; falling back to cache');
      await _tryFallbackToCached();
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthState.authenticating();

    // Check connectivity first
    try {
      final connectivity = ref.read(connectivityServiceProvider);
      final isOnline = await connectivity.isOnline();
      if (!isOnline) {
        // If device has no internet, check if there is an existing cached user
        final cached = await _repository.getCachedUser();
        if (cached != null) {
          _handleUserLoaded(cached);
          return;
        } else {
          state = AuthState.error(
            'Internet connection is required to sign in with Google for the first time.',
          );
          return;
        }
      }
    } catch (_) {
      // Proceed to attempt Google sign-in
    }

    try {
      await _repository.signInWithGoogle();
      // The auth-state listener handles the completed OAuth redirect.
    } catch (error) {
      debugPrint('Google sign-in failed ($error)');
      final cached = await _repository.getCachedUser();
      if (cached != null) {
        _handleUserLoaded(cached);
      } else {
        state = AuthState.error(error.toString());
      }
    }
  }

  void _handleUserLoaded(AppUser user) {
    if (!user.isActive) {
      state = AuthState.inactiveUser(user);
    } else if (user.role == UserRole.gangman) {
      state = AuthState.authorizedGangman(user);
    } else if (user.role == UserRole.admin) {
      state = AuthState.authorizedAdmin(user);
    } else {
      state = AuthState.profilePending(user);
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
      state = AuthState.unauthenticated();
    } catch (error) {
      state = AuthState.error('Sign-out failed: $error');
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == UserRole.admin;
});

final isGangmanProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == UserRole.gangman;
});
