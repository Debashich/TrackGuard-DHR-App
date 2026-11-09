import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trackguard_dhr/core/constants/dhr_waypoints.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';

const _kKmUnit = 'km';

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

    // If no explicit waypoint was selected, default to the one matching active km
    _selection ??= _nearestTo(_activeKm);
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
    final waypoints = DhrWaypoints.waypoints;
    final nearest = _nearestTo(_activeKm);

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header Row (Mockup Design)
                Row(
                  children: [
                    // Location Icon Container
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Symbols.location_on_rounded,
                          color: Color(0xFF074E95),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title
                    const Expanded(
                      child: Text(
                        'Select Nearest DHR Station /\nWaypoint',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: Color(0xFF0A1E3F),
                          height: 1.25,
                        ),
                      ),
                    ),

                    // Close Button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF0F172A),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Km marker input card (Mockup Design with notched label and inner filled box)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Outer Card with thin border
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Symbols.linear_scale_rounded,
                              color: Color(0xFF0077D8),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _kmController,
                                onTapOutside: (_) =>
                                    FocusManager.instance.primaryFocus?.unfocus(),
                                onSubmitted: (_) =>
                                    FocusManager.instance.primaryFocus?.unfocus(),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                textInputAction: TextInputAction.done,
                                cursorColor: const Color(0xFF074E95),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  final parsed = double.tryParse(val);
                                  if (parsed != null) {
                                    setState(() {
                                      _activeKm = parsed;
                                      _selection = _nearestTo(parsed);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              _kKmUnit,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Floating Notched Label "Edit Km Marker"
                    Positioned(
                      left: 14,
                      top: 0,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: const Text(
                          'Edit Km Marker',
                          style: TextStyle(
                            color: Color(0xFF074E95),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stations list with timeline line & radio nodes (Mockup Design)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: waypoints.length,
                    itemBuilder: (context, index) {
                      final wp = waypoints[index];
                      final isSelected = wp.id == _selection?.id;
                      final isNearest = wp.id == nearest?.id;

                      return _StationTile(
                        waypoint: wp,
                        isFirst: index == 0,
                        isLast: index == waypoints.length - 1,
                        isSelected: isSelected,
                        isNearest: isNearest,
                        onTap: () {
                          setState(() {
                            _selection = wp;
                            _activeKm = wp.km;
                            _kmController.text = wp.km.toStringAsFixed(1);
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Action: "Use Selected Location" (Mockup Design)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF074E95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF074E95).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_selection != null) {
                          widget.onWaypointSelected(_selection!);
                          widget.onKmChanged(_activeKm);
                        }
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Symbols.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Use Selected Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    final l10n = AppLocalizations.of(context)!;
    final sectionName = DhrWaypoints.getSectionName(waypoint.sectionId);

    return Semantics(
      selected: isSelected,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline line with circular radio node
            SizedBox(
              width: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Continuous vertical timeline rail
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 2,
                        margin: EdgeInsets.only(
                          top: isFirst ? 20 : 0,
                          bottom: isLast ? 20 : 0,
                        ),
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),

                  // Radio Node
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF074E95)
                            : const Color(0xFFCBD5E1),
                        width: isSelected ? 2.0 : 1.8,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF074E95),
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Station Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF074E95)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.stationName(waypoint.id),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Km ${waypoint.km.toStringAsFixed(1)}  •  $sectionName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isNearest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.0,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF86EFAC),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Symbols.location_on_rounded,
                                      size: 12,
                                      color: Color(0xFF16A34A),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Nearest',
                                      style: TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
