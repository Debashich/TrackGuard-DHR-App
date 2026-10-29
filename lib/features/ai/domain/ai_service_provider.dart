import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../data/ai_analysis_service_impl.dart';
import '../data/cactus_gemma_provider.dart';
import '../data/online_gemini_provider.dart';
import 'ai_analysis_service.dart';

final aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AiAnalysisServiceImpl(
    onlineGemini: OnlineGeminiProvider(supabaseClient: supabase),
  );
});

final isAiModelReadyProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(aiAnalysisServiceProvider);
  return service.isOfflineModelAvailable();
});

final offlineGemmaStateProvider = StreamProvider<CactusGemmaState>((ref) {
  final service = ref.watch(aiAnalysisServiceProvider);
  return service.watchOfflineModelState();
});
