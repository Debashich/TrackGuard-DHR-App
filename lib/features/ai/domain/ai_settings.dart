import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum AiMode {
  automatic,
  offlineGemma,
  onlineGemini,
  manual;

  static AiMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'offlinegemma':
      case 'offline_gemma':
        return AiMode.offlineGemma;
      case 'onlinegemini':
      case 'online_gemini':
        return AiMode.onlineGemini;
      case 'manual':
        return AiMode.manual;
      case 'automatic':
      default:
        return AiMode.automatic;
    }
  }

  String toJson() => name;
}

class AiSettings {
  final AiMode mode;
  final bool allowOnlineGemini;
  final bool allowOfflineGemma;
  final bool saveImagesForAi;
  final bool requireHumanConfirmation;

  const AiSettings({
    this.mode = AiMode.automatic,
    this.allowOnlineGemini = true,
    this.allowOfflineGemma = true,
    this.saveImagesForAi = false,
    this.requireHumanConfirmation = true,
  });

  AiSettings copyWith({
    AiMode? mode,
    bool? allowOnlineGemini,
    bool? allowOfflineGemma,
    bool? saveImagesForAi,
    bool? requireHumanConfirmation,
  }) {
    return AiSettings(
      mode: mode ?? this.mode,
      allowOnlineGemini: allowOnlineGemini ?? this.allowOnlineGemini,
      allowOfflineGemma: allowOfflineGemma ?? this.allowOfflineGemma,
      saveImagesForAi: saveImagesForAi ?? this.saveImagesForAi,
      requireHumanConfirmation:
          requireHumanConfirmation ?? this.requireHumanConfirmation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.toJson(),
      'allow_online_gemini': allowOnlineGemini,
      'allow_offline_gemma': allowOfflineGemma,
      'save_images_for_ai': saveImagesForAi,
      'require_human_confirmation': requireHumanConfirmation,
    };
  }

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    return AiSettings(
      mode: AiMode.fromString(json['mode'] as String?),
      allowOnlineGemini: json['allow_online_gemini'] as bool? ?? true,
      allowOfflineGemma: json['allow_offline_gemma'] as bool? ?? true,
      saveImagesForAi: json['save_images_for_ai'] as bool? ?? false,
      requireHumanConfirmation:
          json['require_human_confirmation'] as bool? ?? true,
    );
  }
}

class AiSettingsNotifier extends Notifier<AiSettings> {
  static const _fileName = 'ai_settings.json';

  @override
  AiSettings build() {
    _loadFromDisk();
    return const AiSettings();
  }

  Future<File> _getFile() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'trackguard'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File(p.join(dir.path, _fileName));
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);
        state = AiSettings.fromJson(json);
      }
    } catch (_) {
      // Keep defaults on failure
    }
  }

  Future<void> _saveToDisk(AiSettings settings) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(settings.toJson()));
    } catch (_) {}
  }

  void setMode(AiMode mode) {
    state = state.copyWith(mode: mode);
    _saveToDisk(state);
  }

  void setAllowOnlineGemini(bool value) {
    state = state.copyWith(allowOnlineGemini: value);
    _saveToDisk(state);
  }

  void setAllowOfflineGemma(bool value) {
    state = state.copyWith(allowOfflineGemma: value);
    _saveToDisk(state);
  }

  void setSaveImagesForAi(bool value) {
    state = state.copyWith(saveImagesForAi: value);
    _saveToDisk(state);
  }
}

final aiSettingsProvider = NotifierProvider<AiSettingsNotifier, AiSettings>(() {
  return AiSettingsNotifier();
});
