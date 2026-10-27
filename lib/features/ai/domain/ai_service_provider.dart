import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_analysis_service_impl.dart';
import 'ai_analysis_service.dart';

final aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  return AiAnalysisServiceImpl();
});

final isAiModelReadyProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(aiAnalysisServiceProvider);
  return service.isOfflineModelAvailable();
});
