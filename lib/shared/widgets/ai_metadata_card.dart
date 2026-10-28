import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../models/ai_analysis_result.dart';
import '../models/ai_provider.dart';
import '../models/app_language.dart';
import '../models/hazard_report.dart';

class AiMetadataCard extends StatelessWidget {
  final AiAnalysisResult? result;
  final AiProvider provider;
  final String? modelName;
  final AppLanguage? language;
  final double? confidence;
  final bool showAdvisoryNotice;

  AiMetadataCard({
    super.key,
    this.result,
    AiProvider? provider,
    String? modelName,
    AppLanguage? language,
    double? confidence,
    this.showAdvisoryNotice = true,
  }) : provider = provider ?? result?.provider ?? AiProvider.manual,
       modelName = modelName ?? result?.modelName,
       language = language ?? result?.language,
       confidence = confidence ?? result?.confidence;

  factory AiMetadataCard.fromResult({
    Key? key,
    required AiAnalysisResult result,
    bool showAdvisoryNotice = true,
  }) {
    return AiMetadataCard(
      key: key,
      result: result,
      provider: result.provider,
      modelName: result.modelName,
      language: result.language,
      confidence: result.confidence,
      showAdvisoryNotice: showAdvisoryNotice,
    );
  }

  factory AiMetadataCard.fromReport(
    HazardReport report, {
    Key? key,
    bool showAdvisoryNotice = true,
  }) {
    return AiMetadataCard(
      key: key,
      provider: report.aiProvider,
      modelName: report.aiModel,
      language: report.aiLanguage,
      confidence: report.aiConfidence,
      showAdvisoryNotice: showAdvisoryNotice,
    );
  }

  String _providerDisplayName(AppLocalizations l10n) {
    switch (provider) {
      case AiProvider.offlineGemma:
        return l10n.aiProviderOfflineGemma;
      case AiProvider.onlineGemini:
        return l10n.aiProviderOnlineGemini;
      case AiProvider.heuristic:
        return l10n.aiProviderHeuristic;
      case AiProvider.manual:
        return l10n.aiProviderManual;
    }
  }

  IconData get _providerIcon {
    switch (provider) {
      case AiProvider.offlineGemma:
        return Icons.psychology;
      case AiProvider.onlineGemini:
        return Icons.cloud_done_rounded;
      case AiProvider.heuristic:
        return Icons.bolt;
      case AiProvider.manual:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final providerTitle = _providerDisplayName(l10n);
    final displayModel =
        modelName ??
        (provider == AiProvider.offlineGemma
            ? 'Gemma 4 E2B'
            : provider == AiProvider.heuristic
            ? 'Rule-based Heuristics'
            : 'Manual Classification');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Icon(_providerIcon, size: 18, color: AppTheme.primaryAmber),
                const SizedBox(width: 8),
                Text(
                  'AI ADVISORY METADATA',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryAmber,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDarkElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Text(
                    provider.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metadata Grid / Rows
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _buildMetaItem(
                  label: l10n.aiProviderLabel,
                  value: providerTitle,
                ),
                if (provider != AiProvider.manual)
                  _buildMetaItem(label: l10n.aiModelLabel, value: displayModel),
                if (language != null)
                  _buildMetaItem(
                    label: l10n.aiLanguageLabel,
                    value: language!.displayName,
                  ),
                if (confidence != null)
                  _buildMetaItem(
                    label: l10n.aiConfidenceLabel,
                    value: '${(confidence! * 100).toStringAsFixed(0)}%',
                  ),
              ],
            ),

            // Mandatory Advisory Notice
            if (showAdvisoryNotice) ...[
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppTheme.primaryAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.aiAdvisoryNotice,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.3,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
