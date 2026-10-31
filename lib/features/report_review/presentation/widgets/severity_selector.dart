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

  Color _severityColor(Severity severity) => switch (severity) {
    Severity.low => AppTheme.statusGreen,
    Severity.medium => AppTheme.statusAmber,
    Severity.high => AppTheme.statusOrange,
    Severity.critical => AppTheme.statusRed,
  };

  String _severityLabel(BuildContext context, Severity severity) {
    final l10n = AppLocalizations.of(context);
    return switch (severity) {
      Severity.low => l10n?.severityLow ?? 'Low',
      Severity.medium => l10n?.severityMedium ?? 'Medium',
      Severity.high => l10n?.severityHigh ?? 'High',
      Severity.critical => l10n?.severityCritical ?? 'Critical',
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: Severity.values.map((severity) {
            final selected = severity == selectedSeverity;
            final color = _severityColor(severity);
            return SizedBox(
              width: width,
              height: 76,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelected(severity),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.10)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? color : AppTheme.borderDark,
                      width: 1.5,
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
                          _severityLabel(context, severity),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check, size: 18, color: color),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
