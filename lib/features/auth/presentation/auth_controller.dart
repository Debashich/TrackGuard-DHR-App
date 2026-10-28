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
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _restoreSession();
    return AuthState.unauthenticated();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        _handleUserLoaded(user);
      }
    } catch (_) {}
  }

  Future<void> signInWithGoogle() async {
    state = AuthState.authenticating();
    try {
      final user = await _repository.signInWithGoogle();
      _handleUserLoaded(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool isSignUp = false,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
        isSignUp: isSignUp,
      );
      _handleUserLoaded(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signInDevelopment({
    required UserRole role,
    bool isActive = true,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _repository.signInDevelopment(
        role: role,
        isActive: isActive,
      );
      _handleUserLoaded(user);
    } catch (e) {
      state = AuthState.error(e.toString());
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
    await _repository.signOut();
    state = AuthState.unauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});
