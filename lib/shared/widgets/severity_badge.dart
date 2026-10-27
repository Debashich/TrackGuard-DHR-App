import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/severity.dart';
import '../../l10n/app_localizations.dart';

class SeverityBadge extends StatelessWidget {
  final Severity severity;
  final bool isLarge;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.isLarge = false,
  });

  Color get _color {
    switch (severity) {
      case Severity.low:
        return AppTheme.statusGreen;
      case Severity.medium:
        return AppTheme.statusAmber;
      case Severity.high:
        return AppTheme.statusOrange;
      case Severity.critical:
        return AppTheme.statusRed;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (severity) {
      case Severity.low:
        return l10n.severityLow;
      case Severity.medium:
        return l10n.severityMedium;
      case Severity.high:
        return l10n.severityHigh;
      case Severity.critical:
        return l10n.severityCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _color;
    final text = l10n != null ? _label(l10n) : severity.name.toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: isLarge ? 14 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
