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
        ? (l10n?.onlineStatus ?? 'Online')
        : (l10n?.offlineStatus ?? 'Offline mode — ready');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
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
                color: isOnline ? const Color(0xFF14532D) : AppTheme.textSecondary,
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
