class AiProviderConfig {
  static const String offlineGemmaModelName = 'Gemma 4 E2B';
  static const String offlineGemmaSlug = 'gemma-4-e2b-litertlm';
  static const String offlineGemmaRepository =
      'litert-community/gemma-4-E2B-it-litert-lm';
  static const String offlineGemmaFile = 'gemma-4-E2B-it.litertlm';
  static const String offlineGemmaBranch = 'main';
  static const String offlineGemmaVersion = 'litertlm-gemma4-e2b-v1';
  static const String offlineGemmaSha256 = '';
  static const int offlineGemmaMinSizeBytes = 2 * 1024 * 1024 * 1024; // 2 GB
  static const int offlineGemmaEstimatedSizeBytes =
      2600 * 1024 * 1024; // ~2.6 GB

  static const String openRouterApiUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String openRouterDefaultModel =
      'nvidia/nemotron-3.5-super-vl:free';
  static const String onlineGeminiModelLabel =
      'Nemotron 3.5 Super VL (OpenRouter)';
  static const String promptVersion = 'phase4-v1';

  static String buildHuggingFaceResolveUrl({
    String repository = offlineGemmaRepository,
    String branch = offlineGemmaBranch,
    String file = offlineGemmaFile,
  }) {
    return 'https://huggingface.co/$repository/resolve/$branch/$file?download=true';
  }

  static String buildHuggingFaceRepoUrl({
    String repository = offlineGemmaRepository,
  }) {
    return 'https://huggingface.co/$repository';
  }

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
