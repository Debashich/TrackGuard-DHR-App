import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/localization/l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_language.dart';

/// Top-bar Language Selector button that opens a clean, compact dropdown menu
/// directly beneath the icon with zero gap and no clutter.
class LanguageSelectorButton extends ConsumerWidget {
  final Color? iconColor;

  const LanguageSelectorButton({
    super.key,
    this.iconColor,
  });

  void _openPopup(BuildContext context, WidgetRef ref) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Select Language',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _LanguageDropdownPopup(
          anchorOffset: offset,
          anchorSize: size,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isRight = (offset.dx + size.width / 2) > (screenWidth / 2);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            alignment: isRight ? Alignment.topRight : Alignment.topLeft,
            scale: curved,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = iconColor ?? const Color(0xFF0F172A);

    return IconButton(
      icon: Icon(
        Symbols.translate_indic_rounded,
        size: 24,
        color: color,
      ),
      tooltip: l10n?.selectLanguage ?? 'Select Language',
      onPressed: () => _openPopup(context, ref),
    );
  }
}

class _LanguageDropdownPopup extends ConsumerWidget {
  final Offset anchorOffset;
  final Size anchorSize;

  const _LanguageDropdownPopup({
    required this.anchorOffset,
    required this.anchorSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.sizeOf(context);
    final currentLang = ref.watch(appLanguageProvider);
    const popupWidth = 220.0;

    final isRight =
        (anchorOffset.dx + anchorSize.width / 2) > (screenSize.width / 2);

    // Place popup snug directly beneath the AppBar/icon without any floating gap
    final top = anchorOffset.dy + anchorSize.height - 2.0;

    double? left;
    double? right;

    if (isRight) {
      right = (screenSize.width - (anchorOffset.dx + anchorSize.width))
          .clamp(6.0, 24.0);
    } else {
      left = anchorOffset.dx.clamp(6.0, 24.0);
    }

    return Stack(
      children: [
        // 1. Barrier: dismiss on tap outside
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),

        // 2. Clean, compact dropdown card
        Positioned(
          top: top,
          left: left,
          right: right,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: popupWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Clean Header
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.translate_indic_rounded,
                            size: 18,
                            color: Color(0xFF074E95),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Select Language',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 4),

                    // Language Option Rows
                    ...AppLanguage.values.map((lang) {
                      final isSelected = lang == currentLang;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(appLanguageProvider.notifier)
                                .setLanguage(lang);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                // Clean Radio Indicator
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF074E95)
                                          : const Color(0xFF94A3B8),
                                      width: isSelected ? 2.0 : 1.5,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF074E95),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    lang.displayName,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF074E95)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Symbols.check_rounded,
                                    size: 17,
                                    color: Color(0xFF074E95),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
