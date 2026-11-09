import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/reports/domain/report_repository_provider.dart';
import '../../l10n/app_localizations.dart';
import 'trackguard_dialog.dart';

Future<bool?> showLogoutConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _LogoutConfirmationDialog(),
  );
}

class _LogoutConfirmationDialog extends ConsumerStatefulWidget {
  const _LogoutConfirmationDialog();

  @override
  ConsumerState<_LogoutConfirmationDialog> createState() =>
      _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState
    extends ConsumerState<_LogoutConfirmationDialog> {
  bool _isSigningOut = false;

  Future<void> _handleConfirm() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final syncSummary = ref.watch(syncSummaryProvider);
    final pendingCount = syncSummary.pendingCount + syncSummary.failedCount;
    final hasPendingReports = pendingCount > 0;

    return TrackGuardDialog(
      icon: Icons.logout_rounded,
      isDestructive: true,
      title: l10n.logoutTitle,
      message: l10n.logoutConfirmation,
      content: hasPendingReports
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppTheme.primaryAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.logoutPendingReportsWarning(pendingCount),
                          style: const TextStyle(
                            fontSize: 12,
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
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            )
          : null,
      primaryLabel: l10n.logoutConfirm,
      primaryIcon: Icons.logout_rounded,
      onPrimaryPressed: _isSigningOut ? null : _handleConfirm,
      isPrimaryLoading: _isSigningOut,
      cancelLabel: l10n.logoutCancel,
      onCancelPressed: _isSigningOut ? null : () => Navigator.of(context).pop(false),
    );
  }
}
