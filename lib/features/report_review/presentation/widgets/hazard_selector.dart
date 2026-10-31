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
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: HazardType.values.map((type) {
          final isSelected = type == selectedHazard;
          return SizedBox(
            width: width,
            height: 72,
            child: Material(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceDarkElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isSelected ? AppTheme.primaryBlue : AppTheme.borderDark, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelected(type),
                child: Stack(children: [
                  Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    HazardIcon(hazardType: type, size: 23),
                    const SizedBox(width: 8),
                    Flexible(child: Text(HazardIcon.getLocalizedLabel(context, type), maxLines: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppTheme.textPrimary))),
                  ])),
                  if (isSelected) const Positioned(right: 5, top: 5, child: Icon(Icons.check_circle, color: Colors.white, size: 16)),
                ]),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
