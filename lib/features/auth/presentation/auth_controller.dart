import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../data/auth_repository.dart';
import '../data/development_auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return _sharedAuthRepo;
});

final _sharedAuthRepo = DevelopmentAuthRepository();

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
          state = AuthState.error(error.toString());
        }
      },
    );

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    _restoreSession();

    return AuthState.unauthenticated();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await _repository.getCurrentUser();

      if (user != null) {
        _handleUserLoaded(user);
      }
    } on ProfileNotFoundException {
      state = AuthState.profilePending();
    } catch (error) {
      state = AuthState.error(error.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthState.authenticating();

    try {
      await _repository.signInWithGoogle();
      // The auth-state listener handles the completed OAuth redirect.
    } catch (error) {
      state = AuthState.error(error.toString());
    }
  }

  Future<void> signInDevelopment({
    required UserRole role,
    bool isActive = true,
  }) async {
    if (!kDebugMode) {
      state = AuthState.error('Development sign-in is disabled.');
      return;
    }

    state = AuthState.authenticating();

    try {
      final user = await _repository.signInDevelopment(
        role: role,
        isActive: isActive,
      );
      _handleUserLoaded(user);
    } catch (error) {
      state = AuthState.error(error.toString());
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
