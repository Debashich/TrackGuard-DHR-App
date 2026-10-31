class AiProviderConfig {
  static const String offlineGemmaModelName = 'Gemma 4 E2B';
  static const String offlineGemmaSlug = 'gemma-4-e2b';
  static const String offlineGemmaRepository =
      'lmstudio-community/gemma-4-E2B-it-GGUF';
  static const String offlineGemmaFile = 'gemma-4-E2B-it-Q4_K_M.gguf';
  static const String offlineGemmaProjectorFile =
      'mmproj-gemma-4-E2B-it-BF16.gguf';
  static const String offlineGemmaBranch = 'main';
  static const String offlineGemmaVersion = 'phase4-gemma4-e2b-v1';
  static const String offlineGemmaSha256 = '';
  static const int offlineGemmaMinSizeBytes = 50 * 1024 * 1024; // 50 MB
  static const int offlineGemmaEstimatedSizeBytes =
      1500 * 1024 * 1024; // ~1.5 GB

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
    return 'https://huggingface.co/$repository/resolve/$branch/$file';
  }

  static String buildHuggingFaceProjectorResolveUrl({
    String repository = offlineGemmaRepository,
    String branch = offlineGemmaBranch,
    String file = offlineGemmaProjectorFile,
  }) {
    return 'https://huggingface.co/$repository/resolve/$branch/$file';
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
