import 'ai_provider.dart';
import 'app_language.dart';
import 'hazard_type.dart';
import 'severity.dart';

class AiAnalysisResult {
  final HazardType? hazardType;
  final Severity? severity;
  final String? note;
  final AiProvider provider;
  final String? modelName;
  final AppLanguage? language;
  final double? confidence;
  final AiProvider? requestedProvider;
  final String? fallbackReason;

  const AiAnalysisResult({
    this.hazardType,
    this.severity,
    this.note,
    this.provider = AiProvider.manual,
    this.modelName,
    this.language,
    this.confidence,
    this.requestedProvider,
    this.fallbackReason,
  });

  AiAnalysisResult copyWith({
    HazardType? hazardType,
    Severity? severity,
    String? note,
    AiProvider? provider,
    String? modelName,
    AppLanguage? language,
    double? confidence,
    AiProvider? requestedProvider,
    String? fallbackReason,
  }) {
    return AiAnalysisResult(
      hazardType: hazardType ?? this.hazardType,
      severity: severity ?? this.severity,
      note: note ?? this.note,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      language: language ?? this.language,
      confidence: confidence ?? this.confidence,
      requestedProvider: requestedProvider ?? this.requestedProvider,
      fallbackReason: fallbackReason ?? this.fallbackReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hazard_type': hazardType?.toJson(),
      'severity': severity?.toJson(),
      'note': note,
      'provider': provider.toJson(),
      'model_name': modelName,
      'language': language?.code,
      'confidence': confidence,
      if (requestedProvider != null)
        'requested_provider': requestedProvider!.toJson(),
      if (fallbackReason != null) 'fallback_reason': fallbackReason,
    };
  }

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      hazardType: json['hazard_type'] != null
          ? HazardType.fromString(json['hazard_type'] as String?)
          : null,
      severity: json['severity'] != null
          ? Severity.fromString(json['severity'] as String?)
          : null,
      note: json['note'] as String?,
      provider: AiProvider.fromString(json['provider'] as String?),
      modelName: json['model_name'] as String?,
      language: json['language'] != null
          ? AppLanguage.fromCode(json['language'] as String?)
          : null,
      confidence: (json['confidence'] as num?)?.toDouble(),
      requestedProvider: json['requested_provider'] != null
          ? AiProvider.fromString(json['requested_provider'] as String?)
          : null,
      fallbackReason: json['fallback_reason'] as String?,
    );
  }
}
