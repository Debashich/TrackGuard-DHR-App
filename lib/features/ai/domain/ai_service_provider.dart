import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../data/ai_analysis_service_impl.dart';
import '../data/cactus_gemma_provider.dart';
import '../data/cactus_offline_model_manager.dart';
import '../data/online_gemini_provider.dart';
import 'ai_analysis_service.dart';
import 'offline_model_manager.dart';
import 'offline_model_state.dart';

final offlineModelManagerProvider = Provider<OfflineModelManager>((ref) {
  final manager = CactusOfflineModelManager();
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

final offlineModelStateProvider = StreamProvider<OfflineModelState>((ref) {
  final manager = ref.watch(offlineModelManagerProvider);
  return manager.watchState();
});

final cactusGemmaProvider = Provider<CactusGemmaProvider>((ref) {
  final manager = ref.watch(offlineModelManagerProvider);
  return CactusGemmaProvider(modelManager: manager);
});

final aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final gemma = ref.watch(cactusGemmaProvider);
  return AiAnalysisServiceImpl(
    cactusGemma: gemma,
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
