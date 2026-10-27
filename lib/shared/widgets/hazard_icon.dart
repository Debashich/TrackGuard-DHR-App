import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/hazard_type.dart';
import '../../l10n/app_localizations.dart';

class HazardIcon extends StatelessWidget {
  final HazardType hazardType;
  final double size;
  final bool showLabel;

  const HazardIcon({
    super.key,
    required this.hazardType,
    this.size = 24.0,
    this.showLabel = false,
  });

  IconData get _icon {
    switch (hazardType) {
      case HazardType.slip:
        return Icons.landscape;
      case HazardType.rockfall:
        return Icons.warning_amber_rounded;
      case HazardType.blockedDrain:
        return Icons.water_damage;
      case HazardType.damagedWall:
        return Icons.handyman;
      case HazardType.trackDefect:
        return Icons.train;
      case HazardType.vegetation:
        return Icons.park;
      case HazardType.other:
        return Icons.report_problem;
    }
  }

  Color get _color {
    switch (hazardType) {
      case HazardType.trackDefect:
      case HazardType.slip:
        return AppTheme.statusRed;
      case HazardType.rockfall:
      case HazardType.damagedWall:
        return AppTheme.statusOrange;
      case HazardType.blockedDrain:
        return AppTheme.primaryAmber;
      case HazardType.vegetation:
        return AppTheme.statusGreen;
      case HazardType.other:
        return Colors.white70;
    }
  }

  static String getLocalizedLabel(BuildContext context, HazardType type) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return type.name;
    switch (type) {
      case HazardType.slip:
        return l10n.hazardSlip;
      case HazardType.rockfall:
        return l10n.hazardRockfall;
      case HazardType.blockedDrain:
        return l10n.hazardBlockedDrain;
      case HazardType.damagedWall:
        return l10n.hazardDamagedWall;
      case HazardType.trackDefect:
        return l10n.hazardTrackDefect;
      case HazardType.vegetation:
        return l10n.hazardVegetation;
      case HazardType.other:
        return l10n.hazardOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 1),
      ),
      child: Icon(_icon, size: size, color: _color),
    );

    if (!showLabel) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 8),
        Text(
          getLocalizedLabel(context, hazardType),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
