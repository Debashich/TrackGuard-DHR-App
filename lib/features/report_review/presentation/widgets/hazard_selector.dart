import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';

class HazardSelector extends StatelessWidget {
  final HazardType selectedHazard;
  final ValueChanged<HazardType> onSelected;

  const HazardSelector({
    super.key,
    required this.selectedHazard,
    required this.onSelected,
  });

  String _getLabel(HazardType type) {
    switch (type) {
      case HazardType.slip:
        return 'Landslide /\nSlip';
      case HazardType.rockfall:
        return 'Boulder /\nRockfall';
      case HazardType.blockedDrain:
        return 'Blocked\nDrain';
      case HazardType.damagedWall:
        return 'Retaining\nWall';
      case HazardType.trackDefect:
        return 'Track Defect /\nJoint';
      case HazardType.vegetation:
        return 'Vegetation\nOvergrowth';
      case HazardType.other:
        return 'Other Defect / Hazard';
    }
  }

  IconData _getIcon(HazardType type) {
    switch (type) {
      case HazardType.slip:
        return Symbols.landscape_rounded;
      case HazardType.rockfall:
        return Symbols.warning_amber_rounded;
      case HazardType.blockedDrain:
        return Symbols.water_damage_rounded;
      case HazardType.damagedWall:
        return Symbols.construction_rounded;
      case HazardType.trackDefect:
        return Symbols.build_rounded;
      case HazardType.vegetation:
        return Symbols.park_rounded;
      case HazardType.other:
        return Symbols.more_horiz_rounded;
    }
  }

  Color _getCircleBg(HazardType type) {
    switch (type) {
      case HazardType.slip:
        return const Color(0xFFFFE4E6); // Light red/salmon
      case HazardType.rockfall:
        return const Color(0xFFFEF3C7); // Light amber
      case HazardType.blockedDrain:
      case HazardType.damagedWall:
        return const Color(0xFFFFEDD5); // Light orange
      case HazardType.trackDefect:
        return const Color(0xFFDBEAFE); // Light blue
      case HazardType.vegetation:
        return const Color(0xFFDCFCE7); // Light green
      case HazardType.other:
        return const Color(0xFFF1F5F9); // Light grey
    }
  }

  Color _getIconColor(HazardType type) {
    switch (type) {
      case HazardType.slip:
        return const Color(0xFFE11D48); // Salmon / Red
      case HazardType.rockfall:
        return const Color(0xFFD97706); // Amber
      case HazardType.blockedDrain:
      case HazardType.damagedWall:
        return const Color(0xFFEA580C); // Orange
      case HazardType.trackDefect:
        return const Color(0xFF074E95); // Blue
      case HazardType.vegetation:
        return const Color(0xFF16A34A); // Green
      case HazardType.other:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;
        final normalHazards = HazardType.values
            .where((t) => t != HazardType.other)
            .toList();

        return Column(
          children: [
            // 2-column grid of 6 primary hazard types
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: normalHazards.map((type) {
                final isSelected = type == selectedHazard;

                return SizedBox(
                  width: cardWidth,
                  height: 64,
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
                      onTap: () => onSelected(type),
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Rounded Icon Circle
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _getCircleBg(type),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIcon(type),
                                      size: 18,
                                      color: _getIconColor(type),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Hazard Label
                                  Expanded(
                                    child: Text(
                                      _getLabel(type),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                        height: 1.2,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Blue checkmark top-right when selected
                          if (isSelected)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Symbols.check_circle_rounded,
                                color: Color(0xFF074E95),
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Full-width "Other Defect / Hazard" row
            Builder(
              builder: (context) {
                const type = HazardType.other;
                final isSelected = type == selectedHazard;

                return SizedBox(
                  width: double.infinity,
                  height: 44,
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
                      onTap: () => onSelected(type),
                      child: Stack(
                        children: [
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _getCircleBg(type),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIcon(type),
                                    size: 16,
                                    color: _getIconColor(type),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getLabel(type),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (isSelected)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Symbols.check_circle_rounded,
                                color: Color(0xFF074E95),
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
