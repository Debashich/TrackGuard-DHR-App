import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import 'language_selector_button.dart';

/// Standard branded TrackGuard DHR App Bar:
/// - Extreme Left: Language translation selector (Material Symbols translate_indic)
/// - Center: App title "TrackGuard DHR"
/// - Extreme Right: Profile navigation icon
class TrackGuardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final Widget? leading;
  final List<Widget>? extraActions;
  final bool showProfile;
  final bool showLanguage;

  const TrackGuardAppBar({
    super.key,
    this.titleText = 'TrackGuard DHR',
    this.leading,
    this.extraActions,
    this.showProfile = true,
    this.showLanguage = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      centerTitle: true,
      leading: leading ??
          (showLanguage
              ? const LanguageSelectorButton(iconColor: AppTheme.textPrimary)
              : null),
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
        if (extraActions != null) ...extraActions!,
        if (showProfile)
          IconButton(
            icon: const Icon(Symbols.person_rounded, size: 24, color: AppTheme.textPrimary),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
      ],
    );
  }
}
