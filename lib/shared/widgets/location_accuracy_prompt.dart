import 'package:flutter/material.dart';

import '../../core/permissions/permission_service.dart';
import '../../l10n/app_localizations.dart';

class LocationAccuracyPrompt extends StatefulWidget {
  final Widget child;

  const LocationAccuracyPrompt({required this.child, super.key});

  @override
  State<LocationAccuracyPrompt> createState() => _LocationAccuracyPromptState();
}

class _LocationAccuracyPromptState extends State<LocationAccuracyPrompt> {
  final PermissionService _permissionService = DefaultPermissionService();
  bool _hasShownPrompt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasShownPrompt) return;
    _hasShownPrompt = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showPrompt();
      }
    });
  }

  Future<void> _showPrompt() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldTurnOn = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.locationAccuracyPromptTitle),
        content: SingleChildScrollView(
          child: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(text: '${l10n.locationAccuracyPromptMessage}\n\n'),
                TextSpan(
                  text: '${l10n.locationAccuracyPromptSettingsHeading}\n',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      '${l10n.locationAccuracyPromptDeviceLocation}\n'
                      '${l10n.locationAccuracyPromptLocationAccuracy}\n\n',
                ),
                TextSpan(
                  text:
                      '${l10n.locationAccuracyPromptExplanation}\n\n'
                      '${l10n.locationAccuracyPromptManageSettingsOr}',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.locationAccuracyPromptNoThanks),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.locationAccuracyPromptTurnOn),
          ),
        ],
      ),
    );

    if (shouldTurnOn != true || !mounted) return;

    final permissionGranted = await _permissionService
        .requestLocationPermission();
    if (!mounted) return;

    final serviceEnabled = await _permissionService.isLocationServiceEnabled();
    if (!permissionGranted || !serviceEnabled) {
      await _permissionService.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
