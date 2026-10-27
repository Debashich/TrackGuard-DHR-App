import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/app_language.dart';

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.en;

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

final appLanguageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(() {
  return LanguageNotifier();
});

final currentLocaleProvider = Provider<Locale>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return Locale(lang.code);
});
