import '../../../shared/models/app_user.dart';

class ProfileNotFoundException implements Exception {
  final String userId;

  const ProfileNotFoundException(this.userId);

  @override
  String toString() =>
      'Your account is signed in, but its TrackGuard profile is not provisioned.';
}

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();

  Future<AppUser?> getCurrentUser();

  Future<void> signInWithGoogle();

  Future<void> signOut();

  Future<AppUser?> loadProfile(String userId);

  Future<AppUser?> getCachedUser();
}
