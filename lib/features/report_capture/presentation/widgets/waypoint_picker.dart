import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackguard_dhr/core/constants/dhr_waypoints.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';

// Strings below are not localized yet; move them into the .arb files.
const _kNearest = 'Nearest';
const _kKmUnit = 'km';

/// Same palette as the capture screen so the sheet reads as part of it.
/// If you'd rather have one source of truth, move this into a shared file.
abstract final class _C {
  static const surface = Color(0xFF111A17);
  static const surfaceHigh = Color(0xFF18241F);
  static const brass = Color(0xFFD9A441);
  static const text = Color(0xFFEAF1EE);
  static const textDim = Color(0xFF9DB0A8);
  static final hairline = Colors.white.withValues(alpha: 0.10);
  static final rail = Colors.white.withValues(alpha: 0.14);
}

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
  late final TextEditingController _kmController;
  DhrWaypoint? _selection;
  late double _activeKm;

  @override
  void initState() {
    super.initState();
    _selection = widget.selectedWaypoint;
    _activeKm = widget.currentKm ?? _selection?.km ?? 51.0;
    _kmController = TextEditingController(text: _activeKm.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  DhrWaypoint? _nearestTo(double km) {
    final all = DhrWaypoints.waypoints;
    if (all.isEmpty) return null;
    return all.reduce(
      (a, b) => (a.km - km).abs() <= (b.km - km).abs() ? a : b,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final waypoints = DhrWaypoints.waypoints;
    final nearest = _nearestTo(_activeKm);

    return Material(
      color: _C.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: _C.hairline),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.selectWaypoint,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: _C.text,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.07),
                      clipBehavior: Clip.antiAlias,
                      shape: CircleBorder(side: BorderSide(color: _C.hairline)),
                      child: IconButton(
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        iconSize: 20,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        icon: const Icon(Icons.close_rounded, color: _C.text),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Km marker field
                TextField(
                  controller: _kmController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textInputAction: TextInputAction.done,
                  cursorColor: _C.brass,
                  style: const TextStyle(
                    color: _C.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.editKm,
                    labelStyle: const TextStyle(color: _C.textDim),
                    floatingLabelStyle: const TextStyle(
                      color: _C.brass,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(
                      Icons.linear_scale_rounded,
                      color: _C.brass,
                    ),
                    suffixText: _kKmUnit,
                    suffixStyle: const TextStyle(
                      color: _C.textDim,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: _C.surfaceHigh,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _C.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _C.brass, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      setState(() => _activeKm = parsed);
                      widget.onKmChanged(parsed);
                    }
                  },
                  onSubmitted: (_) => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),

                // Stations as a line of stops
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: waypoints.length,
                    itemBuilder: (context, index) {
                      final wp = waypoints[index];
                      final isSelected = wp.id == _selection?.id;
                      return _StationTile(
                        waypoint: wp,
                        isFirst: index == 0,
                        isLast: index == waypoints.length - 1,
                        isSelected: isSelected,
                        isNearest: !isSelected && wp.id == nearest?.id,
                        onTap: () {
                          setState(() {
                            _selection = wp;
                            _activeKm = wp.km;
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
          ),
        ),
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({
    required this.waypoint,
    required this.isFirst,
    required this.isLast,
    required this.isSelected,
    required this.isNearest,
    required this.onTap,
  });

  final DhrWaypoint waypoint;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final bool isNearest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: Material(
        color: isSelected
            ? _C.brass.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Expanded(child: _railLine(visible: !isFirst)),
                      _node(),
                      Expanded(child: _railLine(visible: !isLast)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          waypoint.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isSelected ? _C.brass : _C.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Km ${waypoint.km.toStringAsFixed(1)}  ·  ${DhrWaypoints.getSectionName(waypoint.sectionId)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _C.textDim,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 12),
                  child: Center(child: _trailing()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _railLine({required bool visible}) => Center(
    child: Container(
      width: 2,
      color: visible ? _C.rail : Colors.transparent,
    ),
  );

  Widget _node() => SizedBox(
    width: 20,
    height: 20,
    child: Center(
      child: isSelected
          ? Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.brass,
                border: Border.all(
                  color: _C.brass.withValues(alpha: 0.3),
                  width: 4,
                ),
              ),
            )
          : Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.surface,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
            ),
    ),
  );

  Widget _trailing() {
    if (isSelected) {
      return const Icon(Icons.check_circle_rounded, color: _C.brass, size: 22);
    }
    if (isNearest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.brass.withValues(alpha: 0.5)),
        ),
        child: const Text(
          _kNearest,
          style: TextStyle(
            color: _C.brass,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}