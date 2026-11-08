import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Official Google Material Symbol `translate_indic` representing
/// Indian multilingual language translation (A / अ).
class LanguageTranslateIcon extends StatelessWidget {
  final double size;
  final Color color;

  const LanguageTranslateIcon({
    super.key,
    this.size = 28.0,
    this.color = const Color(0xFF0F172A),
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Symbols.translate_indic_rounded,
      size: size,
      color: color,
    );
  }
}
