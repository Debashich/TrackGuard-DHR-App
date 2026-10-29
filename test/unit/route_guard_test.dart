import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trackguard_dhr/app/router.dart';
import 'package:trackguard_dhr/features/auth/domain/auth_state.dart';
import 'package:trackguard_dhr/shared/models/app_language.dart';
import 'package:trackguard_dhr/shared/models/app_user.dart';
import 'package:trackguard_dhr/shared/models/sync_summary.dart';
import 'package:trackguard_dhr/shared/models/user_role.dart';

class _FakeGoRouterState implements GoRouterState {
  @override
  final Uri uri;

  _FakeGoRouterState(String path) : uri = Uri.parse(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final fakeContext = _FakeBuildContext();

  final gangmanUser = AppUser(
    id: 'gangman-001',
    fullName: 'Ramesh Sharma',
    email: 'ramesh.sharma@dhr.railways.gov.in',
    role: UserRole.gangman,
    assignedSection: 'kurseong-ghum',
    preferredLanguage: AppLanguage.en,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final adminUser = AppUser(
    id: 'admin-001',
    fullName: 'Debashish Banerjee',
    email: 'admin@dhr.railways.gov.in',
    role: UserRole.admin,
    assignedSection: null,
    preferredLanguage: AppLanguage.en,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final inactiveUser = AppUser(
    id: 'inactive-001',
    fullName: 'Inactive User',
    email: 'inactive@dhr.railways.gov.in',
    role: UserRole.gangman,
    assignedSection: 'kurseong-ghum',
    preferredLanguage: AppLanguage.en,
    isActive: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Role Helper Functions', () {
    test('isGangman accurately identifies gangman users', () {
      expect(isGangman(gangmanUser), isTrue);
      expect(isGangman(adminUser), isFalse);
      expect(isGangman(null), isFalse);
    });

    test('isAdmin accurately identifies admin users', () {
      expect(isAdmin(adminUser), isTrue);
      expect(isAdmin(gangmanUser), isFalse);
      expect(isAdmin(null), isFalse);
    });
  });

  group('canAccessRoute Verification', () {
    test('Auth routes are accessible from any auth status', () {
      expect(
        canAccessRoute(null, AuthStatus.unauthenticated, '/auth/sign-in'),
        isTrue,
      );
      expect(
        canAccessRoute(null, AuthStatus.profilePending, '/auth/pending'),
        isTrue,
      );
      expect(
        canAccessRoute(inactiveUser, AuthStatus.inactiveUser, '/auth/inactive'),
        isTrue,
      );
    });

    test('Unauthenticated or invalid auth statuses block protected routes', () {
      expect(
        canAccessRoute(null, AuthStatus.unauthenticated, '/gangman/home'),
        isFalse,
      );
      expect(
        canAccessRoute(null, AuthStatus.authenticating, '/gangman/home'),
        isFalse,
      );
      expect(
        canAccessRoute(null, AuthStatus.authError, '/gangman/home'),
        isFalse,
      );
      expect(
        canAccessRoute(null, AuthStatus.profilePending, '/gangman/home'),
        isFalse,
      );
      expect(
        canAccessRoute(inactiveUser, AuthStatus.inactiveUser, '/gangman/home'),
        isFalse,
      );
      expect(
        canAccessRoute(gangmanUser, AuthStatus.inactiveUser, '/profile'),
        isFalse,
      );
    });

    test('Authorized gangman can access gangman routes and profile/logout', () {
      expect(
        canAccessRoute(
          gangmanUser,
          AuthStatus.authorizedGangman,
          '/gangman/home',
        ),
        isTrue,
      );
      expect(
        canAccessRoute(
          gangmanUser,
          AuthStatus.authorizedGangman,
          '/gangman/reports',
        ),
        isTrue,
      );
      expect(
        canAccessRoute(
          gangmanUser,
          AuthStatus.authorizedGangman,
          '/gangman/report/capture',
        ),
        isTrue,
      );
      expect(
        canAccessRoute(
          gangmanUser,
          AuthStatus.authorizedGangman,
          '/gangman/reports/rep-123',
        ),
        isTrue,
      );
      expect(
        canAccessRoute(gangmanUser, AuthStatus.authorizedGangman, '/profile'),
        isTrue,
      );
      expect(
        canAccessRoute(gangmanUser, AuthStatus.authorizedGangman, '/logout'),
        isTrue,
      );
    });

    test('Authorized gangman cannot access admin routes', () {
      expect(
        canAccessRoute(
          gangmanUser,
          AuthStatus.authorizedGangman,
          '/admin/dashboard',
        ),
        isFalse,
      );
    });

    test('Authorized admin can access admin routes and profile/logout', () {
      expect(
        canAccessRoute(
          adminUser,
          AuthStatus.authorizedAdmin,
          '/admin/dashboard',
        ),
        isTrue,
      );
      expect(
        canAccessRoute(adminUser, AuthStatus.authorizedAdmin, '/profile'),
        isTrue,
      );
      expect(
        canAccessRoute(adminUser, AuthStatus.authorizedAdmin, '/logout'),
        isTrue,
      );
    });

    test('Authorized admin cannot access gangman routes', () {
      expect(
        canAccessRoute(adminUser, AuthStatus.authorizedAdmin, '/gangman/home'),
        isFalse,
      );
      expect(
        canAccessRoute(
          adminUser,
          AuthStatus.authorizedAdmin,
          '/gangman/reports',
        ),
        isFalse,
      );
    });
  });

  group('appRedirect Route Guard Tests', () {
    test('Unauthenticated user is redirected to /auth/sign-in', () {
      final authState = AuthState.unauthenticated();

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/gangman/home'),
          authState,
        ),
        '/auth/sign-in',
      );
      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/admin/dashboard'),
          authState,
        ),
        '/auth/sign-in',
      );
      expect(
        appRedirect(fakeContext, _FakeGoRouterState('/profile'), authState),
        '/auth/sign-in',
      );
      expect(
        appRedirect(fakeContext, _FakeGoRouterState('/logout'), authState),
        '/auth/sign-in',
      );
      // Staying on /auth/sign-in returns null
      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/auth/sign-in'),
          authState,
        ),
        isNull,
      );
    });

    test('Profile pending user is redirected to /auth/pending', () {
      final authState = AuthState.profilePending();

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/gangman/home'),
          authState,
        ),
        '/auth/pending',
      );
      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/admin/dashboard'),
          authState,
        ),
        '/auth/pending',
      );
      // Already on /auth/pending returns null
      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/auth/pending'),
          authState,
        ),
        isNull,
      );
    });

    test('Inactive user is redirected to /auth/inactive', () {
      final authState = AuthState.inactiveUser(inactiveUser);

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/gangman/home'),
          authState,
        ),
        '/auth/inactive',
      );
      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/admin/dashboard'),
          authState,
        ),
        '/auth/inactive',
      );
      // Already on /auth/inactive returns null
      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/auth/inactive'),
          authState,
        ),
        isNull,
      );
    });

    test('Gangman user on /admin/dashboard redirects to /gangman/home', () {
      final authState = AuthState.authorizedGangman(gangmanUser);

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/admin/dashboard'),
          authState,
        ),
        '/gangman/home',
      );
    });

    test('Gangman user on auth routes redirects to /gangman/home', () {
      final authState = AuthState.authorizedGangman(gangmanUser);

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/auth/sign-in'),
          authState,
        ),
        '/gangman/home',
      );
    });

    test('Gangman user on valid gangman and shared routes is allowed', () {
      final authState = AuthState.authorizedGangman(gangmanUser);

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/gangman/home'),
          authState,
        ),
        isNull,
      );
      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/gangman/reports'),
          authState,
        ),
        isNull,
      );
      expect(
        appRedirect(fakeContext, _FakeGoRouterState('/profile'), authState),
        isNull,
      );
      expect(
        appRedirect(fakeContext, _FakeGoRouterState('/logout'), authState),
        isNull,
      );
    });

    test('Admin user on /gangman/* routes redirects to /admin/dashboard', () {
      final authState = AuthState.authorizedAdmin(adminUser);

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/gangman/home'),
          authState,
        ),
        '/admin/dashboard',
      );
      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/gangman/reports'),
          authState,
        ),
        '/admin/dashboard',
      );
    });

    test('Admin user on auth routes redirects to /admin/dashboard', () {
      final authState = AuthState.authorizedAdmin(adminUser);

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/auth/sign-in'),
          authState,
        ),
        '/admin/dashboard',
      );
    });

    test('Admin user on valid admin and shared routes is allowed', () {
      final authState = AuthState.authorizedAdmin(adminUser);

      expect(
        appRedirect(
          fakeContext,
          _FakeGoRouterState('/admin/dashboard'),
          authState,
        ),
        isNull,
      );
      expect(
        appRedirect(fakeContext, _FakeGoRouterState('/profile'), authState),
        isNull,
      );
      expect(
        appRedirect(fakeContext, _FakeGoRouterState('/logout'), authState),
        isNull,
      );
    });
  });

  group('Pending Reports Logout Warning Check', () {
    test('Warns user when pending or failed reports exist', () {
      const summaryWithPending = SyncSummary(
        pendingCount: 2,
        syncingCount: 0,
        failedCount: 0,
        syncedCount: 3,
        conflictCount: 0,
        isOnline: false,
      );

      final hasWarning = summaryWithPending.hasPendingOrFailed;
      final pendingTotal =
          summaryWithPending.pendingCount + summaryWithPending.failedCount;

      expect(hasWarning, isTrue);
      expect(pendingTotal, 2);
    });

    test('No warning needed when all reports are synced', () {
      const summarySynced = SyncSummary(
        pendingCount: 0,
        syncingCount: 0,
        failedCount: 0,
        syncedCount: 5,
        conflictCount: 0,
        isOnline: true,
      );

      expect(summarySynced.hasPendingOrFailed, isFalse);
      expect(summarySynced.allSynced, isTrue);
    });
  });
}
