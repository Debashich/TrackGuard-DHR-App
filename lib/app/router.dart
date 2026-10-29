import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin_dashboard/presentation/admin_dashboard_screen.dart';
import '../features/ai/presentation/ai_settings_screen.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/logout_screen.dart';
import '../features/auth/presentation/pending_access_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/report_capture/presentation/report_capture_screen.dart';
import '../features/report_detail/presentation/gangman_report_detail_screen.dart';
import '../features/report_queue/presentation/report_queue_placeholder_screen.dart';
import '../features/report_review/presentation/report_review_screen.dart';
import '../shared/models/app_user.dart';
import '../shared/models/user_role.dart';

bool isGangman(AppUser? user) => user?.role == UserRole.gangman;
bool isAdmin(AppUser? user) => user?.role == UserRole.admin;

bool canAccessRoute(AppUser? user, AuthStatus status, String path) {
  if (path.startsWith('/auth')) return true;

  if (status == AuthStatus.inactiveUser ||
      status == AuthStatus.profilePending ||
      status == AuthStatus.unauthenticated ||
      status == AuthStatus.authenticating ||
      status == AuthStatus.authError) {
    return false;
  }

  if (path == '/profile' || path == '/logout' || path == '/settings/ai') {
    return true;
  }

  if (path.startsWith('/admin')) {
    return status == AuthStatus.authorizedAdmin || isAdmin(user);
  }

  if (path.startsWith('/gangman')) {
    return status == AuthStatus.authorizedGangman || isGangman(user);
  }

  return false;
}

String? appRedirect(
  BuildContext context,
  GoRouterState state,
  AuthState authState,
) {
  final location = state.uri.path;
  final status = authState.status;

  final isAuthRoute = location.startsWith('/auth');
  final isAdminRoute = location.startsWith('/admin');
  final isGangmanRoute = location.startsWith('/gangman');

  switch (status) {
    case AuthStatus.unauthenticated:
    case AuthStatus.authenticating:
    case AuthStatus.authError:
      return isAuthRoute ? null : '/auth/sign-in';

    case AuthStatus.profilePending:
      return location == '/auth/pending' ? null : '/auth/pending';

    case AuthStatus.inactiveUser:
      return location == '/auth/inactive' ? null : '/auth/inactive';

    case AuthStatus.authorizedAdmin:
      if (isAuthRoute &&
          location != '/auth/pending' &&
          location != '/auth/inactive') {
        return '/admin/dashboard';
      }
      if (isGangmanRoute) {
        return '/admin/dashboard';
      }
      return null;

    case AuthStatus.authorizedGangman:
    case AuthStatus.authenticated:
    case AuthStatus.loadingProfile:
      if (isAuthRoute &&
          location != '/auth/pending' &&
          location != '/auth/inactive') {
        return '/gangman/home';
      }
      if (isAdminRoute) {
        return '/gangman/home';
      }
      return null;
  }
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/auth/sign-in',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      return appRedirect(context, state, authState);
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/pending',
        builder: (context, state) =>
            const PendingAccessScreen(isInactive: false),
      ),
      GoRoute(
        path: '/auth/inactive',
        builder: (context, state) =>
            const PendingAccessScreen(isInactive: true),
      ),

      // Shared Authenticated Routes
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings/ai',
        builder: (context, state) => const AiSettingsScreen(),
      ),
      GoRoute(
        path: '/logout',
        builder: (context, state) => const LogoutScreen(),
      ),

      // Gangman Routes
      GoRoute(
        path: '/gangman/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/gangman/report/capture',
        builder: (context, state) => const ReportCaptureScreen(),
      ),
      GoRoute(
        path: '/gangman/report/review',
        builder: (context, state) => const ReportReviewScreen(),
      ),
      GoRoute(
        path: '/gangman/reports',
        builder: (context, state) => const ReportQueueScreen(),
      ),
      GoRoute(
        path: '/gangman/reports/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GangmanReportDetailScreen(reportId: id);
        },
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
