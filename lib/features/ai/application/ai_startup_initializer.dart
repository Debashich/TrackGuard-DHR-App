import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ai_service_provider.dart';
import '../domain/offline_model_manager.dart';
import '../domain/offline_model_state.dart';

enum AiStartupReadinessStatus {
  idle,
  checking,
  initializing,
  ready,
  unavailable,
  corrupted,
}

class AiStartupReadiness {
  final AiStartupReadinessStatus status;
  final String message;
  final String? error;

  const AiStartupReadiness({
    required this.status,
    required this.message,
    this.error,
  });

  bool get isReady => status == AiStartupReadinessStatus.ready;
  bool get isInitializing =>
      status == AiStartupReadinessStatus.initializing ||
      status == AiStartupReadinessStatus.checking;
}

class AiStartupInitializer {
  final OfflineModelManager modelManager;
  final StreamController<AiStartupReadiness> _readinessController =
      StreamController<AiStartupReadiness>.broadcast();

  AiStartupReadiness _currentReadiness = const AiStartupReadiness(
    status: AiStartupReadinessStatus.idle,
    message: 'Offline AI readiness check pending.',
  );

  bool _hasStarted = false;

  AiStartupInitializer({
    required this.modelManager,
  });

  AiStartupReadiness get currentReadiness => _currentReadiness;
  Stream<AiStartupReadiness> get readinessStream =>
      _readinessController.stream;

  /// Runs background check and automatic activation if a verified model exists.
  /// Never blocks the caller; does NOT download without user consent.
  Future<void> initializeOnStartup() async {
    if (_hasStarted) return;
    _hasStarted = true;

    _updateReadiness(
      const AiStartupReadiness(
        status: AiStartupReadinessStatus.checking,
        message: 'Checking offline model...',
      ),
    );

    // Non-blocking background activation
    unawaited(_performBackgroundActivation());
  }

  Future<void> _performBackgroundActivation() async {
    try {
      // 1. Check availability with strict artifact validation
      await modelManager.checkAvailability();
      final state = await modelManager.getState();

      if (state.status == OfflineModelStatus.ready) {
        _updateReadiness(
          const AiStartupReadiness(
            status: AiStartupReadinessStatus.ready,
            message: 'Offline Gemma ready',
          ),
        );
        return;
      }

      if (state.status == OfflineModelStatus.downloaded) {
        // Model weights exist and passed validation -> automatically initialize
        _updateReadiness(
          const AiStartupReadiness(
            status: AiStartupReadinessStatus.initializing,
            message: 'Initializing Gemma 4 E2B...',
          ),
        );

        try {
          await modelManager.initialize();
          _updateReadiness(
            const AiStartupReadiness(
              status: AiStartupReadinessStatus.ready,
              message: 'Offline Gemma ready',
            ),
          );
        } catch (initError) {
          debugPrint('Automatic startup initialization deferred: $initError');
          _updateReadiness(
            AiStartupReadiness(
              status: AiStartupReadinessStatus.unavailable,
              message: 'Offline Gemma unavailable',
              error: initError.toString(),
            ),
          );
        }
        return;
      }

      if (state.status == OfflineModelStatus.corrupted) {
        _updateReadiness(
          AiStartupReadiness(
            status: AiStartupReadinessStatus.corrupted,
            message: 'Offline model corrupted',
            error: state.errorMessage,
          ),
        );
        return;
      }

      // Model is not downloaded (needs download)
      _updateReadiness(
        const AiStartupReadiness(
          status: AiStartupReadinessStatus.unavailable,
          message: 'Offline Gemma unavailable',
        ),
      );
    } catch (e) {
      debugPrint('AI startup initializer encountered error: $e');
      _updateReadiness(
        AiStartupReadiness(
          status: AiStartupReadinessStatus.unavailable,
          message: 'Offline Gemma unavailable',
          error: e.toString(),
        ),
      );
    }
  }

  void _updateReadiness(AiStartupReadiness readiness) {
    _currentReadiness = readiness;
    _readinessController.add(readiness);
  }

  void dispose() {
    _readinessController.close();
  }
}

final aiStartupInitializerProvider = Provider<AiStartupInitializer>((ref) {
  final manager = ref.watch(offlineModelManagerProvider);
  final initializer = AiStartupInitializer(modelManager: manager);
  ref.onDispose(() {
    initializer.dispose();
  });
  return initializer;
});

final aiStartupReadinessProvider =
    StreamProvider<AiStartupReadiness>((ref) {
  final initializer = ref.watch(aiStartupInitializerProvider);
  return initializer.readinessStream;
});

