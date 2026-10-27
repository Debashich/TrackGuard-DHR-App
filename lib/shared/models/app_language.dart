enum AppLanguage {
  en('en', 'English'),
  hi('hi', 'हिंदी (Hindi)'),
  bn('bn', 'বাংলা (Bengali)'),
  ne('ne', 'नेपाली (Nepali)');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'hi':
        return AppLanguage.hi;
      case 'bn':
        return AppLanguage.bn;
      case 'ne':
        return AppLanguage.ne;
      case 'en':
      default:
        return AppLanguage.en;
    }
  }
}
