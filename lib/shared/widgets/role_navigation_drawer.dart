import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/dhr_waypoints.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/user_role.dart';
import 'logout_confirmation.dart';

class RoleNavigationDrawer extends ConsumerWidget {
  final String currentRoute;

  const RoleNavigationDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin;

    final sectionName = user?.assignedSection != null
        ? DhrWaypoints.getSectionName(user!.assignedSection!)
        : (isAdmin ? l10n.allDhrAlignment : l10n.unassignedSection);

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Hero Profile Card (Matches User Profile Screen Design)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: _buildHeroProfileCard(
                context,
                user: user,
                isAdmin: isAdmin,
                sectionName: sectionName,
                l10n: l10n,
              ),
            ),

            const SizedBox(height: 4),

            // 2. Navigation items list with redesigned modern daylight tabs
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                    child: Text(
                      'MAIN NAVIGATION',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (isAdmin) ...[
                    _buildNavTab(
                      context,
                      icon: Symbols.dashboard_rounded,
                      label: l10n.navigationDashboard,
                      route: '/admin/dashboard',
                      isSelected: currentRoute == '/admin/dashboard',
                    ),
                    _buildNavTab(
                      context,
                      icon: Symbols.person_rounded,
                      label: l10n.navigationProfile,
                      route: '/profile',
                      isSelected: currentRoute == '/profile',
                    ),
                  ] else ...[
                    _buildNavTab(
                      context,
                      icon: Symbols.home_rounded,
                      label: l10n.navigationHome,
                      route: '/gangman/home',
                      isSelected: currentRoute == '/gangman/home',
                    ),
                    _buildNavTab(
                      context,
                      icon: Symbols.photo_camera_rounded,
                      label: l10n.newReport,
                      route: '/gangman/report/capture',
                      isSelected: currentRoute == '/gangman/report/capture',
                    ),
                    _buildNavTab(
                      context,
                      icon: Symbols.assignment_rounded,
                      label: l10n.navigationMyReports,
                      route: '/gangman/reports',
                      isSelected: currentRoute == '/gangman/reports',
                    ),
                    _buildNavTab(
                      context,
                      icon: Symbols.person_rounded,
                      label: l10n.navigationProfile,
                      route: '/profile',
                      isSelected: currentRoute == '/profile',
                    ),
                  ],
                ],
              ),
            ),

            // 3. Bottom Sign Out Section (Matches User Profile Screen Design)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
              ),
              child: _buildSignOutButton(context, ref: ref, l10n: l10n),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Hero Profile Card ─────────────────────────

  Widget _buildHeroProfileCard(
    BuildContext context, {
    required AppUser? user,
    required bool isAdmin,
    required String sectionName,
    required AppLocalizations l10n,
  }) {
    final roleBadgeText = (isAdmin ? l10n.roleAdmin : l10n.roleGangman)
        .toUpperCase();
    final displayName = user?.fullName ?? (isAdmin ? 'Supervisor' : 'Gangman');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF074E95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF074E95).withValues(alpha: 0.28),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Bottom-right decorative diagonal hazard stripes
            Positioned(
              bottom: -2,
              right: -2,
              child: SizedBox(
                width: 90,
                height: 40,
                child: CustomPaint(
                  painter: _DiagonalStripesPainter(
                    color: const Color(0x351E88E5),
                    strokeWidth: 4.5,
                    spacing: 9.0,
                  ),
                ),
              ),
            ),

            // Content row wrapped in InkWell for navigation to Profile
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  if (currentRoute != '/profile') {
                    final profileRoute = currentRoute == '/admin/dashboard'
                        ? '/admin/dashboard/profile'
                        : '/profile';
                    context.push(profileRoute);
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      // Circular White Avatar with shield/engineering icon
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isAdmin
                                ? Symbols.shield_person_rounded
                                : Symbols.engineering_rounded,
                            color: const Color(0xFF074E95),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Vertical divider
                      Container(
                        width: 1,
                        height: 48,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    roleBadgeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? '—',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Symbols.alt_route_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    sectionName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Redesigned Nav Tabs ─────────────────────────

  Widget _buildNavTab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEBF3FC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFC7DCF5) : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            if (!isSelected) {
              if (route == '/profile' && currentRoute == '/admin/dashboard') {
                context.push('/admin/dashboard/profile');
              } else {
                context.go(route);
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF074E95)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color:
                          isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Label Text
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF074E95)
                          : const Color(0xFF1E293B),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),

                // Active Chevron Indicator
                if (isSelected)
                  const Icon(
                    Symbols.chevron_right_rounded,
                    color: Color(0xFF074E95),
                    size: 20,
                  )
                else
                  const Icon(
                    Symbols.chevron_right_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Sign Out Button (From Profile Screen) ─────────────────────────

  Widget _buildSignOutButton(
    BuildContext context, {
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            showLogoutConfirmationDialog(context, ref);
          },
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.signOut,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Decorative Painter ─────────────────────────

class _DiagonalStripesPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double spacing;

  const _DiagonalStripesPainter({
    required this.color,
    this.strokeWidth = 3.5,
    this.spacing = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final total = size.width + size.height;
    for (double i = -size.height; i < total; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter oldDelegate) =>
      color != oldDelegate.color;
}
