import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';

class SeveritySelector extends StatelessWidget {
  final Severity selectedSeverity;
  final ValueChanged<Severity> onSelected;

  const SeveritySelector({
    super.key,
    required this.selectedSeverity,
    required this.onSelected,
  });

  Color _severityDotColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return const Color(0xFF22C55E); // Green
      case Severity.medium:
        return const Color(0xFFF59E0B); // Amber
      case Severity.high:
        return const Color(0xFFF97316); // Orange
      case Severity.critical:
        return const Color(0xFFEF4444); // Red
    }
  }

  String _tierCode(Severity severity) {
    switch (severity) {
      case Severity.low:
        return 'LOW';
      case Severity.medium:
        return 'MED';
      case Severity.high:
        return 'HIGH';
      case Severity.critical:
        return 'CRIT';
    }
  }

  String _tierLabel(Severity severity) {
    switch (severity) {
      case Severity.low:
        return 'Monitor';
      case Severity.medium:
        return 'Maintain';
      case Severity.high:
        return 'Urgent';
      case Severity.critical:
        return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Severity.values.map((severity) {
        final isSelected = severity == selectedSeverity;
        final dotColor = _severityDotColor(severity);
        final isLast = severity == Severity.values.last;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 6),
            child: SizedBox(
              height: 56,
              child: Material(
                color: isSelected
                    ? const Color(0xFFE8F1FA)
                    : const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF074E95)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelected(severity),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Tier Code + Dot
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _tierCode(severity),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: isSelected
                                        ? const Color(0xFF074E95)
                                        : const Color(0xFF0F172A),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),

                            // Subtitle label
                            Text(
                              _tierLabel(severity),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF074E95)
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Checkmark badge when selected
                      if (isSelected)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Symbols.check_circle_rounded,
                            color: Color(0xFF074E95),
                            size: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
