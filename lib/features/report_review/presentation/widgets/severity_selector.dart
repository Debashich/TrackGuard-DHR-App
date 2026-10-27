import 'package:flutter/material.dart';
import 'package:trackguard_dhr/app/theme.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';

class SeveritySelector extends StatelessWidget {
  final Severity selectedSeverity;
  final ValueChanged<Severity> onSelected;

  const SeveritySelector({
    super.key,
    required this.selectedSeverity,
    required this.onSelected,
  });

  Color _severityColor(Severity s) {
    switch (s) {
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

  String _severityLabel(BuildContext context, Severity s) {
    final l10n = AppLocalizations.of(context);
    switch (s) {
      case Severity.low:
        return l10n?.severityLow ?? 'Low';
      case Severity.medium:
        return l10n?.severityMedium ?? 'Medium';
      case Severity.high:
        return l10n?.severityHigh ?? 'High';
      case Severity.critical:
        return l10n?.severityCritical ?? 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Severity.values.map((s) {
        final isSelected = s == selectedSeverity;
        final color = _severityColor(s);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : AppTheme.surfaceDarkElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : AppTheme.borderDark,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _severityLabel(context, s),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                  if (isSelected) Icon(Icons.check, size: 18, color: color),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
