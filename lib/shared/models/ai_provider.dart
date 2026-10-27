enum AiProvider {
  offlineGemma,
  onlineGemini,
  heuristic,
  manual;

  static AiProvider fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'offlinegemma':
      case 'offline_gemma':
      case 'gemma':
        return AiProvider.offlineGemma;
      case 'onlinegemini':
      case 'online_gemini':
      case 'gemini':
        return AiProvider.onlineGemini;
      case 'heuristic':
        return AiProvider.heuristic;
      case 'manual':
      default:
        return AiProvider.manual;
    }
  }

  String toJson() => name;
}
