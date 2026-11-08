import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/localization/l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_language.dart';

class LanguageSelectorButton extends ConsumerWidget {
  final Color? iconColor;

  const LanguageSelectorButton({
    super.key,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = ref.watch(appLanguageProvider);
    final color = iconColor ?? const Color(0xFF0F172A);

    return PopupMenuButton<AppLanguage>(
      icon: Icon(
        Symbols.translate_indic_rounded,
        size: 26,
        color: color,
      ),
      tooltip: l10n.selectLanguage,
      onSelected: (lang) {
        ref.read(appLanguageProvider.notifier).setLanguage(lang);
      },
      itemBuilder: (context) => AppLanguage.values.map((lang) {
        final isSelected = lang == currentLang;
        return PopupMenuItem<AppLanguage>(
          value: lang,
          child: Row(
            children: [
              if (isSelected)
                Icon(
                  Symbols.check_rounded,
                  size: 18,
                  color: color,
                )
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(
                lang.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
