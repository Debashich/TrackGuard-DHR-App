import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/localization/l10n.dart';
import '../../../features/auth/presentation/auth_controller.dart';
import '../../ai/domain/ai_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/logout_confirmation.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final isAdmin = user?.role == UserRole.admin;

    final sectionName = user?.assignedSection != null
        ? DhrWaypoints.getSectionName(user!.assignedSection!)
        : (isAdmin ? l10n.allDhrAlignment : l10n.unassignedSection);

    final dashboardRoute = isAdmin ? '/admin/dashboard' : '/gangman/home';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            l10n.profileTitle,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A1E3F),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0A1E3F)),
            tooltip: l10n.navigationBack,
            onPressed: () {
              if (isAdmin) {
                context.go(dashboardRoute);
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go(dashboardRoute);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              tooltip: l10n.signOut,
              onPressed: () => showLogoutConfirmationDialog(context, ref),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 14.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Profile Banner Card (Mockup Design)
                _buildHeroProfileCard(
                  context,
                  user: user,
                  isAdmin: isAdmin,
                  sectionName: sectionName,
                  l10n: l10n,
                ),
                const SizedBox(height: 14),

                // 2. Account Details Card (Mockup Design)
                _buildAccountDetailsCard(
                  context,
                  user: user,
                  isAdmin: isAdmin,
                  sectionName: sectionName,
                  l10n: l10n,
                ),
                const SizedBox(height: 14),

                // 3. Preferred Language Selection Card (Mockup Design)
                _buildPreferredLanguageCard(
                  context,
                  ref: ref,
                  currentLang: currentLang,
                  l10n: l10n,
                ),
                const SizedBox(height: 14),

                // 4. AI & Model Settings Card (Mockup Design)
                _buildAiSettingsCard(context, ref: ref, l10n: l10n),
                const SizedBox(height: 14),

                // 5. TrackGuard DHR Alignment Card (Mockup Design)
                _buildAppInfoCard(context, l10n: l10n),
                const SizedBox(height: 16),

                // 6. Sign Out Button (Mockup Design)
                _buildSignOutButton(context, ref: ref, l10n: l10n),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

            // Content row
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

                  // Vertical divider
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
                          user?.email ?? '—',
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

  Widget _buildAccountDetailsCard(
    BuildContext context, {
    required AppUser? user,
    required bool isAdmin,
    required String sectionName,
    required AppLocalizations l10n,
  }) {
    final isActive = user?.isActive ?? true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Icon + "Account Details"
          const Row(
            children: [
              Icon(
                Symbols.person_outline_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Account Details',
                style: TextStyle(
                  color: Color(0xFF0A1E3F),
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Full Name
          _buildDetailItem(
            icon: Symbols.person_outline_rounded,
            label: l10n.profileName,
            value: user?.fullName ?? (isAdmin ? 'Supervisor' : 'Gangman'),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20, thickness: 1.0),

          // 2. Email Address
          _buildDetailItem(
            icon: Symbols.mail_rounded,
            label: l10n.profileEmail,
            value: user?.email ?? '—',
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20, thickness: 1.0),

          // 3. Role
          _buildDetailItem(
            icon: isAdmin
                ? Symbols.admin_panel_settings_rounded
                : Symbols.engineering_rounded,
            label: l10n.profileRole,
            value: isAdmin ? l10n.roleAdmin : l10n.roleGangman,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20, thickness: 1.0),

          // 4. Assigned Section
          _buildDetailItem(
            icon: Symbols.alt_route_rounded,
            label: l10n.profileAssignedSection,
            value: sectionName,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20, thickness: 1.0),

          // 5. Account Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIconBox(Symbols.shield_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileAccountStatus,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive
                                ? Symbols.check_circle_rounded
                                : Symbols.cancel_rounded,
                            size: 14,
                            color: isActive
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive
                                ? l10n.profileActive
                                : l10n.profileInactive,
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIconBox(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, color: const Color(0xFF074E95), size: 19),
      ),
    );
  }

  Widget _buildPreferredLanguageCard(
    BuildContext context, {
    required WidgetRef ref,
    required AppLanguage currentLang,
    required AppLocalizations l10n,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.language_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.profileLanguage,
                style: const TextStyle(
                  color: Color(0xFF0A1E3F),
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Language selection grid matching mockup
          Row(
            children: [
              Expanded(
                child: _buildLanguageChip(ref, AppLanguage.en, currentLang),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLanguageChip(ref, AppLanguage.hi, currentLang),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildLanguageChip(ref, AppLanguage.bn, currentLang),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLanguageChip(ref, AppLanguage.ne, currentLang),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(
    WidgetRef ref,
    AppLanguage lang,
    AppLanguage currentLang,
  ) {
    final isSelected = lang == currentLang;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF074E95) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? null
            : Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(appLanguageProvider.notifier).setLanguage(lang);
          },
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    lang.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      fontSize: 14.0,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiSettingsCard(
    BuildContext context, {
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final modeName = switch (aiSettings.mode) {
      AiMode.automatic => l10n.aiModeAutomaticHelper,
      AiMode.offlineGemma => l10n.aiModeOfflineHelper,
      AiMode.onlineGemini => l10n.aiModeOnlineHelper,
      AiMode.manual => l10n.aiModeManualOnly,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/settings/ai'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(
                  Symbols.smart_toy_rounded,
                  color: Color(0xFF074E95),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aiSettingsTitle,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l10n.smartPhotoHelperTitle} • $modeName',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Symbols.chevron_right_rounded,
                  color: Color(0xFF074E95),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(
    BuildContext context, {
    required AppLocalizations l10n,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Symbols.info_rounded, color: Color(0xFF074E95), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appAlignmentTitle,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.appEditionVersion,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
