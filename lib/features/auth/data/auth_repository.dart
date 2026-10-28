import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';

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

  Future<AppUser> signInDevelopment({
    required UserRole role,
    bool isActive = true,
  });

  Future<void> signOut();

  Future<AppUser?> loadProfile(String userId);
}