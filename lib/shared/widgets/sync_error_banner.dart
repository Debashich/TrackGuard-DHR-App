import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/sync/sync_error_message_mapper.dart';
import '../../l10n/app_localizations.dart';

class SyncErrorBanner extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;
  final bool isDismissible;
  final VoidCallback? onDismiss;

  const SyncErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.isDismissible = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final friendlyMessage = SyncErrorMessageMapper.toUserMessage(error, l10n);
    final technicalCode = SyncErrorMessageMapper.extractTechnicalCode(error);
    final canRetry = SyncErrorMessageMapper.canRetry(error);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.statusRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.statusRed.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.statusRed,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.syncFailed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      friendlyMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    if (technicalCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ref: $technicalCode',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isDismissible && onDismiss != null)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white60,
                  ),
                  onPressed: onDismiss,
                  tooltip: l10n.close,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (onRetry != null && canRetry) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: AppTheme.primaryAmber,
                ),
                label: Text(
                  l10n.retrySync,
                  style: const TextStyle(
                    color: AppTheme.primaryAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(48, 32),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
