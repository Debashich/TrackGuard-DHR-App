import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/user_role.dart';
import 'logout_confirmation.dart';
import 'profile_header.dart';

class RoleNavigationDrawer extends ConsumerWidget {
  final String currentRoute;

  const RoleNavigationDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin;

    return Drawer(
      backgroundColor: AppTheme.surfaceDark,
      child: SafeArea(
        child: Column(
          children: [
            // Top user header
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
              ),
              child: ProfileHeader(
                user: user,
                compact: true,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/profile');
                },
              ),
            ),

            // Navigation items list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (isAdmin) ...[
                    _buildDrawerItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      label: l10n.navigationDashboard,
                      route: '/admin/dashboard',
                      isSelected: currentRoute == '/admin/dashboard',
                    ),
                  ] else ...[
                    _buildDrawerItem(
                      context,
                      icon: Icons.home_outlined,
                      label: l10n.navigationHome,
                      route: '/gangman/home',
                      isSelected: currentRoute == '/gangman/home',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.camera_alt_outlined,
                      label: l10n.newReport,
                      route: '/gangman/report/capture',
                      isSelected: currentRoute == '/gangman/report/capture',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.assignment_outlined,
                      label: l10n.navigationMyReports,
                      route: '/gangman/reports',
                      isSelected: currentRoute == '/gangman/reports',
                    ),
                  ],
                  const Divider(color: AppTheme.borderDark),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline,
                    label: l10n.navigationProfile,
                    route: '/profile',
                    isSelected: currentRoute == '/profile',
                  ),
                ],
              ),
            ),

            // Sign out tile at bottom
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderDark)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.statusRed),
                title: Text(
                  l10n.navigationLogout,
                  style: const TextStyle(
                    color: AppTheme.statusRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  showLogoutConfirmationDialog(context, ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
  }) {
    final activeColor = AppTheme.primaryAmber;

    return ListTile(
      selected: isSelected,
      selectedTileColor: activeColor.withValues(alpha: 0.12),
      leading: Icon(icon, color: isSelected ? activeColor : AppTheme.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? activeColor : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        if (!isSelected) {
          context.go(route);
        }
      },
    );
  }
}
