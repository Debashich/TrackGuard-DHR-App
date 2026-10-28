import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();
  Future<AppUser?> getCurrentUser();
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInDevelopment({
    required UserRole role,
    bool isActive = true,
  });
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
    bool isSignUp = false,
  });
  Future<void> signOut();
  Future<AppUser?> loadProfile(String userId);
}
