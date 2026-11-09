import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/severity.dart';

// import '../../l10n/app_localizations.dart';

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

  Color get _ink {
    switch (severity) {
      case Severity.low:
        return const Color(0xFF14532D);
      case Severity.medium:
        return const Color(0xFF78350F);
      case Severity.high:
        return const Color(0xFF7C2D12);
      case Severity.critical:
        return const Color(0xFF7F1D1D);
    }
  }

  // String _label(AppLocalizations l10n) {
  //   switch (severity) {
  //     case Severity.low:
  //       return l10n.severityLow;
  //     case Severity.medium:
  //       return l10n.severityMedium;
  //     case Severity.high:
  //       return l10n.severityHigh;
  //     case Severity.critical:
  //       return l10n.severityCritical;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    final text = switch (severity) {
      Severity.low => 'Low',
      Severity.medium => 'Medium',
      Severity.high => 'High',
      Severity.critical => 'Critical',
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: switch (severity) {
          Severity.low => const Color(0xFFDCFCE7),
          Severity.medium => const Color(0xFFFEF3C7),
          Severity.high => const Color(0xFFFFEDD5),
          Severity.critical => const Color(0xFFFEE2E2),
        },
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _ink,
          fontSize: isLarge ? 14 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
