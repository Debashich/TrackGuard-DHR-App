import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../features/auth/presentation/auth_controller.dart';
import '../../../features/reports/domain/report_repository_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/primary_button.dart';

class LogoutScreen extends ConsumerStatefulWidget {
  const LogoutScreen({super.key});

  @override
  ConsumerState<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends ConsumerState<LogoutScreen> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        context.go('/auth/sign-in');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.logoutError),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    final user = ref.read(currentUserProvider);
    if (context.canPop()) {
      context.pop();
    } else if (user?.role == UserRole.admin) {
      context.go('/admin/dashboard');
    } else {
      context.go('/gangman/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final syncSummary = ref.watch(syncSummaryProvider);
    final pendingCount = syncSummary.pendingCount + syncSummary.failedCount;
    final hasPendingReports = pendingCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logoutTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSigningOut ? null : _handleCancel,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.logout,
                          color: AppTheme.statusRed,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.logoutTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.logoutConfirmation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (hasPendingReports) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryAmber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 20,
                                  color: AppTheme.primaryAmber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.logoutPendingReportsWarning(
                                      pendingCount,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryAmber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.logoutReportsRemainOnDevice,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: l10n.logoutConfirm.toUpperCase(),
                      icon: Icons.logout,
                      backgroundColor: AppTheme.statusRed,
                      isLoading: _isSigningOut,
                      onPressed: _isSigningOut ? null : _handleSignOut,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.borderDark),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSigningOut ? null : _handleCancel,
                      child: Text(l10n.logoutCancel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
