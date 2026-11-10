import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/dhr_waypoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/logout_confirmation.dart';
import 'auth_controller.dart';

class PendingAccessScreen extends ConsumerWidget {
  final bool isInactive;

  const PendingAccessScreen({super.key, this.isInactive = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;

    final sectionName = user?.assignedSection != null
        ? DhrWaypoints.getSectionName(user!.assignedSection!)
        : (isAdmin ? l10n.allDhrAlignment : l10n.unassignedSection);

    final roleBadgeText =
        (isAdmin ? l10n.roleAdmin : l10n.roleGangman).toUpperCase();
    final displayName = user?.fullName ?? (isAdmin ? 'Supervisor' : 'Gangman');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Symbols.arrow_back_rounded,
            color: Color(0xFF0F172A),
            size: 22,
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              showLogoutConfirmationDialog(context, ref);
            }
          },
        ),
        title: Text(
          l10n.pendingAccessTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Icon
                Icon(
                  isInactive
                      ? Symbols.block_rounded
                      : Symbols.hourglass_top_rounded,
                  size: 64,
                  color: isInactive
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFD97706),
                ),
                const SizedBox(height: 18),

                // Status Title
                Text(
                  isInactive ? l10n.accountInactive : l10n.pendingAccessTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle / Informational Message
                Text(
                  isInactive
                      ? l10n.inactiveAccountMessage
                      : l10n.pendingAccessMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),

                // Blue Profile Card (Sampled from ProfileScreen)
                _buildBlueProfileCard(
                  displayName: displayName,
                  roleBadgeText: roleBadgeText,
                  email: user?.email ?? '—',
                  sectionName: sectionName,
                  isAdmin: isAdmin,
                ),
                const SizedBox(height: 28),

                // Sign Out Button (Matching ProfileScreen design & color)
                _buildSignOutButton(context, ref, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlueProfileCard({
    required String displayName,
    required String roleBadgeText,
    required String email,
    required String sectionName,
    required bool isAdmin,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF074E95),
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
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

            // Content Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Circular White Avatar
                  Container(
                    width: 66,
                    height: 66,
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
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Vertical Divider
                  Container(
                    width: 1,
                    height: 52,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  const SizedBox(width: 14),

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
                                  fontSize: 18.0,
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
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                roleBadgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Symbols.alt_route_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                sectionName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
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
          onTap: () => showLogoutConfirmationDialog(context, ref),
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
                    fontSize: 15.5,
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
