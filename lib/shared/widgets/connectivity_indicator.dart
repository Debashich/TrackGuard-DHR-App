import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

class ConnectivityIndicator extends StatelessWidget {
  final bool isOnline;

  const ConnectivityIndicator({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = isOnline ? AppTheme.statusGreen : AppTheme.statusAmber;
    final text = isOnline
        ? (l10n?.onlineStatus ?? 'Online - Cloud Sync Ready')
        : (l10n?.offlineStatus ?? 'Offline - Local Queue Active');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
