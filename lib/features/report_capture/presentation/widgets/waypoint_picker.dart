import 'package:flutter/material.dart';
import 'package:trackguard_dhr/app/theme.dart';
import 'package:trackguard_dhr/core/constants/dhr_waypoints.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';

class WaypointPickerSheet extends StatefulWidget {
  final DhrWaypoint? selectedWaypoint;
  final double? currentKm;
  final ValueChanged<DhrWaypoint> onWaypointSelected;
  final ValueChanged<double> onKmChanged;

  const WaypointPickerSheet({
    super.key,
    this.selectedWaypoint,
    this.currentKm,
    required this.onWaypointSelected,
    required this.onKmChanged,
  });

  @override
  State<WaypointPickerSheet> createState() => _WaypointPickerSheetState();
}

class _WaypointPickerSheetState extends State<WaypointPickerSheet> {
  late TextEditingController _kmController;
  DhrWaypoint? _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.selectedWaypoint ?? DhrWaypoints.waypoints.first;
    _kmController = TextEditingController(
      text: (widget.currentKm ?? _currentSelection?.km ?? 51.0).toStringAsFixed(
        1,
      ),
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.textPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.selectWaypoint,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Km Marker editor field
          TextField(
            controller: _kmController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.editKm,
              prefixIcon: const Icon(
                Icons.linear_scale,
                color: AppTheme.primaryBlue,
              ),
              suffixText: 'km',
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null) {
                widget.onKmChanged(parsed);
              }
            },
          ),
          const SizedBox(height: 16),
          // List of DHR Stations
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: DhrWaypoints.waypoints.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final wp = DhrWaypoints.waypoints[index];
                final isSelected = wp.id == _currentSelection?.id;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  leading: Icon(
                    Icons.train,
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  ),
                  title: Text(
                    wp.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Km ${wp.km.toStringAsFixed(1)} • ${DhrWaypoints.getSectionName(wp.sectionId)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryBlue,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _currentSelection = wp;
                      _kmController.text = wp.km.toStringAsFixed(1);
                    });
                    widget.onWaypointSelected(wp);
                    widget.onKmChanged(wp.km);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

