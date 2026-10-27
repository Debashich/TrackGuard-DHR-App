import 'dart:async';

import '../../../shared/models/app_language.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import 'auth_repository.dart';

class DevelopmentAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  DevelopmentAuthRepository() {
    // Start unauthenticated
    _currentUser = null;
  }

  @override
  Stream<AppUser?> watchAuthState() => _controller.stream;

  @override
  Future<AppUser?> getCurrentUser() async => _currentUser;

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = AppUser(
      id: 'dhr-gangman-001',
      fullName: 'Ramesh Sharma',
      email: 'ramesh.sharma@dhr.railways.gov.in',
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
    await Future.delayed(const Duration(milliseconds: 300));
    final user = AppUser(
      id: role == UserRole.gangman ? 'dhr-gangman-001' : 'dhr-admin-001',
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
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<AppUser?> loadProfile(String userId) async {
    return _currentUser;
  }
}
