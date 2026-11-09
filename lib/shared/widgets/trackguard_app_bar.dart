import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import 'language_selector_button.dart';

/// Standard branded TrackGuard DHR App Bar:
/// - Left: Gangman Profile navigation icon
/// - Center: App title "TrackGuard DHR"
/// - Right: Language translation selector (Material Symbols translate_indic)
class TrackGuardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final Widget? leading;
  final List<Widget>? extraActions;
  final bool showProfileLeading;
  final bool showProfile;
  final bool showLanguage;

  const TrackGuardAppBar({
    super.key,
    this.titleText = 'TrackGuard DHR',
    this.leading,
    this.extraActions,
    this.showProfileLeading = true,
    this.showProfile = false,
    this.showLanguage = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && showProfileLeading) {
      final tooltip = AppLocalizations.of(context)?.navigationProfile ?? 'Profile';
      effectiveLeading = IconButton(
        icon: const Icon(
          Symbols.person_rounded,
          size: 24,
          color: AppTheme.textPrimary,
        ),
        tooltip: tooltip,
        onPressed: () => context.push('/profile'),
      );
    }

    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      centerTitle: true,
      leading: effectiveLeading,
      title: Text(
        titleText,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        ...?extraActions,
        if (showLanguage)
          const LanguageSelectorButton(iconColor: AppTheme.textPrimary),
        if (showProfile)
          IconButton(
            icon: const Icon(Symbols.person_rounded, size: 24, color: AppTheme.textPrimary),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}
