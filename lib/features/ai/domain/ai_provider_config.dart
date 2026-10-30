class AiProviderConfig {
  static const String offlineGemmaModelName = 'Gemma 4 E2B';
  static const String offlineGemmaSlug = 'gemma-4-e2b-it';
  static const String onlineGeminiModelLabel = 'Gemini (Secure Edge Function)';
  static const String promptVersion = 'phase4-v1';

  static const int maxNoteLength = 500;
  static const double minConfidence = 0.0;
  static const double maxConfidence = 1.0;

  static const List<String> supportedHazardTypes = [
    'slip',
    'rockfall',
    'blockedDrain',
    'damagedWall',
    'trackDefect',
    'vegetation',
    'other',
  ];

  static const List<String> supportedSeverities = [
    'low',
    'medium',
    'high',
    'critical',
  ];
}
