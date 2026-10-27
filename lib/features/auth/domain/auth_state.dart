import '../../../shared/models/app_user.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  loadingProfile,
  profilePending,
  authorizedGangman,
  authorizedAdmin,
  inactiveUser,
  authError,
}

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.authenticating() =>
      const AuthState(status: AuthStatus.authenticating);

  factory AuthState.loadingProfile(AppUser user) =>
      AuthState(status: AuthStatus.loadingProfile, user: user);

  factory AuthState.authorizedGangman(AppUser user) =>
      AuthState(status: AuthStatus.authorizedGangman, user: user);

  factory AuthState.authorizedAdmin(AppUser user) =>
      AuthState(status: AuthStatus.authorizedAdmin, user: user);

  factory AuthState.profilePending(AppUser user) =>
      AuthState(status: AuthStatus.profilePending, user: user);

  factory AuthState.inactiveUser(AppUser user) =>
      AuthState(status: AuthStatus.inactiveUser, user: user);

  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.authError, errorMessage: message);
}
