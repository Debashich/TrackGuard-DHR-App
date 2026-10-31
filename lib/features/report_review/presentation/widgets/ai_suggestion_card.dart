import 'package:flutter/material.dart';
import 'package:trackguard_dhr/app/theme.dart';
import 'package:trackguard_dhr/features/ai/domain/ai_settings.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/ai_analysis_result.dart';
import 'package:trackguard_dhr/shared/models/ai_provider.dart';
import 'package:trackguard_dhr/shared/widgets/hazard_icon.dart';
import 'package:trackguard_dhr/shared/widgets/severity_badge.dart';

class AiSuggestionCard extends StatelessWidget {
  final AiAnalysisResult? aiResult;
  final String? errorMessage;
  final bool isAnalyzing;
  final AiMode? currentMode;
  final VoidCallback? onRetry;
  final VoidCallback? onSwitchToManual;
  final VoidCallback? onDownloadModel;

  const AiSuggestionCard({
    super.key,
    required this.aiResult,
    this.errorMessage,
    required this.isAnalyzing,
    this.currentMode,
    this.onRetry,
    this.onSwitchToManual,
    this.onDownloadModel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final analyzingText = currentMode == AiMode.offlineGemma
        ? l10n.aiAnalyzingOffline
        : currentMode == AiMode.onlineGemini
        ? l10n.aiAnalyzingOnline
        : l10n.aiAnalyzing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: AppTheme.primaryAmber,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.aiSuggestionTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (aiResult != null && !isAnalyzing)
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
                      aiResult!.provider == AiProvider.offlineGemma
                          ? 'Gemma 4 E2B'
                          : aiResult!.provider == AiProvider.onlineGemini
                          ? 'Gemini Cloud'
                          : aiResult!.provider == AiProvider.heuristic
                          ? 'Heuristic'
                          : 'Manual',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isAnalyzing) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryAmber,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  analyzingText,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ] else if (aiResult != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (aiResult!.hazardType != null)
                    HazardIcon(
                      hazardType: aiResult!.hazardType!,
                      size: 18,
                      showLabel: true,
                    ),
                  if (aiResult!.severity != null)
                    SeverityBadge(severity: aiResult!.severity!),
                ],
              ),
              if (aiResult!.note != null && aiResult!.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDarkElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aiResult!.note!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              // Actions row: Switch to Manual / Retry
              const SizedBox(height: 12),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                overflowSpacing: 6,
                children: [
                  if (onDownloadModel != null &&
                      aiResult!.requestedProvider == AiProvider.offlineGemma &&
                      aiResult!.provider != AiProvider.offlineGemma)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                      onPressed: onDownloadModel,
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text(
                        l10n.offlineModelDownload,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (onRetry != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        l10n.aiRetryAnalysis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (onSwitchToManual != null &&
                      aiResult!.provider != AiProvider.manual)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        foregroundColor: AppTheme.textSecondary,
                      ),
                      onPressed: onSwitchToManual,
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: Text(
                        l10n.aiUseManualClassification,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ] else if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.statusRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.statusRed.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.statusRed,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Inference Error',
                            style: TextStyle(
                              color: AppTheme.statusRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  if (onRetry != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        l10n.aiRetryAnalysis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (onSwitchToManual != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.textSecondary,
                      ),
                      onPressed: onSwitchToManual,
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: Text(
                        l10n.aiUseManualClassification,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
            const Divider(height: 16),
            // Mandatory AI advisory disclaimer
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 15,
                  color: AppTheme.primaryAmber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.aiDisclaimer,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
