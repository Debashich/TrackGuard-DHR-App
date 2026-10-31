import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../models/sync_status.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final bool isCompact;

  const SyncStatusBadge({
    super.key,
    required this.status,
    bool isCompact = false,
    bool compact = false,
  }) : isCompact = isCompact || compact;

  Color get _color {
    switch (status) {
      case SyncStatus.synced:
        return AppTheme.statusGreen;
      case SyncStatus.pending:
        return AppTheme.primaryAmber;
      case SyncStatus.syncing:
        return const Color(0xFF64B5F6); // Soft accessible blue
      case SyncStatus.failed:
        return AppTheme.statusRed;
      case SyncStatus.conflict:
        return AppTheme.statusOrange;
      case SyncStatus.draft:
        return AppTheme.textSecondary;
    }
  }

  IconData get _icon {
    switch (status) {
      case SyncStatus.synced:
        return Icons.check_circle_outline;
      case SyncStatus.pending:
        return Icons.schedule;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.failed:
        return Icons.error_outline;
      case SyncStatus.conflict:
        return Icons.warning_amber_rounded;
      case SyncStatus.draft:
        return Icons.edit_note_rounded;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (status) {
      case SyncStatus.synced:
        return l10n.syncStatusSynced;
      case SyncStatus.pending:
        return l10n.syncStatusPending;
      case SyncStatus.syncing:
        return l10n.syncStatusSyncing;
      case SyncStatus.failed:
        return l10n.syncStatusFailed;
      case SyncStatus.conflict:
        return l10n.syncStatusConflict;
      case SyncStatus.draft:
        return l10n.syncStatusDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _color;
    final text = _label(l10n);

    return Semantics(
      label: 'Sync Status: $text',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 10,
          vertical: isCompact ? 2 : 5,
        ),
        decoration: BoxDecoration(
          color: switch (status) {
            SyncStatus.synced => const Color(0xFFDCFCE7),
            SyncStatus.pending => const Color(0xFFFEF3C7),
            SyncStatus.syncing => const Color(0xFFE0F2FE),
            SyncStatus.failed => const Color(0xFFFEE2E2),
            SyncStatus.conflict => const Color(0xFFFFEDD5),
            SyncStatus.draft => const Color(0xFFEEF2F6),
          },
          borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (status == SyncStatus.syncing)
              SizedBox(
                width: isCompact ? 10 : 13,
                height: isCompact ? 10 : 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(_icon, size: isCompact ? 12 : 15, color: color),
            SizedBox(width: isCompact ? 4 : 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
