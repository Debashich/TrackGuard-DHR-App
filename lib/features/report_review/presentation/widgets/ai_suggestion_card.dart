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
  final bool isAnalyzing;
  final AiMode? currentMode;
  final VoidCallback? onRetry;
  final VoidCallback? onSwitchToManual;

  const AiSuggestionCard({
    super.key,
    required this.aiResult,
    required this.isAnalyzing,
    this.currentMode,
    this.onRetry,
    this.onSwitchToManual,
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
                      color: Colors.white,
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
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
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
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              // Actions row: Switch to Manual / Retry
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onRetry != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.primaryAmber,
                      ),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        l10n.aiRetryAnalysis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (onSwitchToManual != null &&
                      aiResult!.provider != AiProvider.manual) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.white60,
                      ),
                      onPressed: onSwitchToManual,
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: Text(
                        l10n.aiUseManualClassification,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
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
                      color: Colors.white.withValues(alpha: 0.6),
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
