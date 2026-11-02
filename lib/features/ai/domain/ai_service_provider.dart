import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../data/ai_analysis_service_impl.dart';
import '../data/litert_gemma_provider.dart';
import '../data/litert_offline_model_manager.dart';
import '../data/online_gemini_provider.dart';
import 'ai_analysis_service.dart';
import 'offline_model_manager.dart';
import 'offline_model_state.dart';

final offlineModelManagerProvider = Provider<OfflineModelManager>((ref) {
  final manager = LitertOfflineModelManager();
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

final litertOfflineModelManagerProvider = offlineModelManagerProvider;

final offlineModelStateProvider = StreamProvider<OfflineModelState>((ref) {
  final manager = ref.watch(offlineModelManagerProvider);
  return manager.watchState();
});

final litertGemmaProvider = Provider<LitertGemmaProvider>((ref) {
  final manager = ref.watch(offlineModelManagerProvider);
  return LitertGemmaProvider(modelManager: manager);
});

final llamaGemmaProvider = litertGemmaProvider;
final cactusGemmaProvider = litertGemmaProvider;

final aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final gemma = ref.watch(litertGemmaProvider);
  return AiAnalysisServiceImpl(
    litertGemma: gemma,
    onlineGemini: OnlineGeminiProvider(supabaseClient: supabase),
  );
});

final isAiModelReadyProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(aiAnalysisServiceProvider);
  return service.isOfflineModelAvailable();
});

final offlineGemmaStateProvider = StreamProvider<LitertGemmaState>((ref) {
  final service = ref.watch(aiAnalysisServiceProvider);
  return service.watchOfflineModelState();
});
