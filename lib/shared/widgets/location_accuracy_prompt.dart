import 'package:flutter/material.dart';

import '../../core/permissions/permission_service.dart';
import '../../l10n/app_localizations.dart';
import 'trackguard_dialog.dart';

class LocationAccuracyPrompt extends StatefulWidget {
  final Widget child;

  const LocationAccuracyPrompt({required this.child, super.key});

  @override
  State<LocationAccuracyPrompt> createState() => _LocationAccuracyPromptState();
}

class _LocationAccuracyPromptState extends State<LocationAccuracyPrompt> {
  final PermissionService _permissionService = DefaultPermissionService();
  static bool _hasPromptedThisSession = false;

  @override
  void initState() {
    super.initState();
    if (_hasPromptedThisSession) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndShowPrompt();
      }
    });
  }

  Future<void> _checkAndShowPrompt() async {
    if (_hasPromptedThisSession) return;

    // First check if location service is already enabled and permission is granted
    try {
      final serviceEnabled =
          await _permissionService.isLocationServiceEnabled();
      final permissionGranted =
          await _permissionService.checkLocationPermission();

      // If location is already active and permission granted, never bother the user
      if (serviceEnabled && permissionGranted) {
        _hasPromptedThisSession = true;
        return;
      }
    } catch (_) {
      // Ignore checks if platform channel fails
    }

    _hasPromptedThisSession = true;
    if (!mounted) return;

    await _showPrompt();
  }

  Future<void> _showPrompt() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final shouldTurnOn = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TrackGuardDialog(
        icon: Icons.my_location_rounded,
        iconBgColor: TrackGuardDialog.brandBlueSoft,
        iconColor: TrackGuardDialog.brandBlue,
        title: l10n.locationAccuracyPromptTitle,
        message: l10n.locationAccuracyPromptMessage,
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.locationAccuracyPromptSettingsHeading,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• ${l10n.locationAccuracyPromptDeviceLocation}\n'
                '• ${l10n.locationAccuracyPromptLocationAccuracy}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.locationAccuracyPromptExplanation,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        primaryLabel: l10n.locationAccuracyPromptTurnOn,
        primaryIcon: Icons.gps_fixed_rounded,
        primaryColor: TrackGuardDialog.brandBlue,
        onPrimaryPressed: () => Navigator.of(ctx).pop(true),
        cancelLabel: l10n.locationAccuracyPromptNoThanks,
        onCancelPressed: () => Navigator.of(ctx).pop(false),
      ),
    );

    if (shouldTurnOn != true || !mounted) return;

    final permissionGranted =
        await _permissionService.requestLocationPermission();
    if (!mounted) return;

    final serviceEnabled =
        await _permissionService.isLocationServiceEnabled();
    if (!permissionGranted || !serviceEnabled) {
      await _permissionService.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
