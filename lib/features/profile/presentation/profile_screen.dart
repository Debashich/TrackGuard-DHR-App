import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/localization/l10n.dart';
import '../../../features/auth/presentation/auth_controller.dart';
import '../../ai/domain/ai_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/logout_confirmation.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/profile_header.dart';

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
        : (isAdmin ? 'All DHR Alignment' : l10n.unassignedSection);

    final dashboardRoute = isAdmin ? '/admin/dashboard' : '/gangman/home';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.navigationBack,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(dashboardRoute);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () => showLogoutConfirmationDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User header card
              ProfileHeader(user: user),
              const SizedBox(height: 16),

              // Profile Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryAmber,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildInfoRow(
                        context,
                        icon: Icons.person_outline,
                        label: l10n.profileName,
                        value:
                            user?.fullName ??
                            (isAdmin ? 'Supervisor' : 'Gangman'),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        icon: Icons.email_outlined,
                        label: l10n.profileEmail,
                        value: user?.email ?? '—',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        icon: isAdmin
                            ? Icons.admin_panel_settings_outlined
                            : Icons.engineering_outlined,
                        label: l10n.profileRole,
                        value: isAdmin ? l10n.roleAdmin : l10n.roleGangman,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        icon: Icons.alt_route,
                        label: l10n.profileAssignedSection,
                        value: sectionName,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        icon: Icons.verified_user_outlined,
                        label: l10n.profileAccountStatus,
                        value: (user?.isActive ?? true)
                            ? l10n.profileActive
                            : l10n.profileInactive,
                        valueColor: (user?.isActive ?? true)
                            ? AppTheme.statusGreen
                            : AppTheme.statusRed,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        icon: Icons.fingerprint,
                        label: 'Profile Identifier',
                        value: user?.id ?? '—',
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preferred Language Selection Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.language,
                            size: 18,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.profileLanguage.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryAmber,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppLanguage.values.map((lang) {
                          final isSelected = lang == currentLang;
                          return ChoiceChip(
                            label: Text(lang.displayName),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryAmber,
                            backgroundColor: AppTheme.surfaceDarkElevated,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryAmber
                                  : AppTheme.borderDark,
                            ),
                            onSelected: (_) {
                              ref
                                  .read(appLanguageProvider.notifier)
                                  .setLanguage(lang);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AI & Model Settings Entry
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.psychology,
                    color: AppTheme.primaryAmber,
                  ),
                  title: Text(
                    l10n.aiSettingsTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Smart Photo Helper • ${ref.watch(aiSettingsProvider).mode.name == 'manual' ? 'Manual' : 'Automatic'}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () => context.push('/settings/ai'),
                ),
              ),
              const SizedBox(height: 16),

              // Application Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TrackGuard DHR Alignment',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Version 1.0.0 • Field Operations Edition',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Return to Dashboard Action
              PrimaryButton(
                text: l10n.profileBackToHome.toUpperCase(),
                icon: isAdmin ? Icons.dashboard : Icons.home,
                onPressed: () => context.go(dashboardRoute),
              ),
              const SizedBox(height: 12),

              // Sign Out Action
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusRed,
                  side: const BorderSide(color: AppTheme.statusRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: Text(l10n.signOut.toUpperCase()),
                onPressed: () => showLogoutConfirmationDialog(context, ref),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMonospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary,
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
