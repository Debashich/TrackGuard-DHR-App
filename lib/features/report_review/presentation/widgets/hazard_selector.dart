import 'package:flutter/material.dart';
import 'package:trackguard_dhr/app/theme.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
import 'package:trackguard_dhr/shared/widgets/hazard_icon.dart';

class HazardSelector extends StatelessWidget {
  final HazardType selectedHazard;
  final ValueChanged<HazardType> onSelected;

  const HazardSelector({
    super.key,
    required this.selectedHazard,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: HazardType.values.map((type) {
        final isSelected = type == selectedHazard;

        return ChoiceChip(
          selected: isSelected,
          onSelected: (_) => onSelected(type),
          selectedColor: AppTheme.primaryAmber,
          backgroundColor: AppTheme.surfaceDarkElevated,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryAmber : AppTheme.borderDark,
            width: isSelected ? 1.5 : 1.0,
          ),
          avatar: HazardIcon(hazardType: type, size: 16),
          label: Text(
            HazardIcon.getLocalizedLabel(context, type),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
}
