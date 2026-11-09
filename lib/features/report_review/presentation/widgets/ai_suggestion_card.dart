import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trackguard_dhr/features/ai/domain/ai_settings.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/ai_analysis_result.dart';
import 'package:trackguard_dhr/shared/models/ai_provider.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
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

  String _getProviderPillText(AiAnalysisResult? result) {
    if (result == null) return 'Gemini Cloud';
    switch (result.provider) {
      case AiProvider.onlineGemini:
        return 'Gemini Cloud';
      case AiProvider.offlineGemma:
        return 'Offline Gemma';
      case AiProvider.heuristic:
        return 'Heuristic';
      case AiProvider.manual:
        return 'Manual';
    }
  }

  IconData _getHazardIcon(HazardType? type) {
    switch (type) {
      case HazardType.trackDefect:
        return Symbols.train_rounded;
      case HazardType.slip:
        return Symbols.landscape_rounded;
      case HazardType.rockfall:
        return Symbols.warning_amber_rounded;
      case HazardType.blockedDrain:
        return Symbols.water_damage_rounded;
      case HazardType.damagedWall:
        return Symbols.construction_rounded;
      case HazardType.vegetation:
        return Symbols.park_rounded;
      default:
        return Symbols.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final providerText = _getProviderPillText(aiResult);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title + Provider Pill
          Row(
            children: [
              const Icon(
                Symbols.smart_toy_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Advisory Suggestion',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  providerText,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF074E95),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Content States
          if (isAnalyzing) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF074E95),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentMode == AiMode.offlineGemma
                          ? l10n.aiAnalyzingOffline
                          : l10n.aiAnalyzingOnline,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (aiResult != null) ...[
            // Suggested Hazard Icon & Severity Badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getHazardIcon(aiResult!.hazardType),
                    size: 22,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const Spacer(),
                if (aiResult!.severity != null)
                  SeverityBadge(severity: aiResult!.severity!),
              ],
            ),
            const SizedBox(height: 12),

            // AI Note Box
            if (aiResult!.note != null && aiResult!.note!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  aiResult!.note!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // Action Buttons (Retry AI Analysis & Switch to Manual)
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onRetry,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.refresh_rounded,
                              size: 18,
                              color: Color(0xFF074E95),
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Retry AI Analysis',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF074E95),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onSwitchToManual,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.edit_note_rounded,
                              size: 18,
                              color: Color(0xFF334155),
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Switch to Manual',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Symbols.error_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Inference Unavailable',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF475569),
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
            Row(
              children: [
                if (onRetry != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF074E95),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onRetry,
                      icon: const Icon(Symbols.refresh_rounded, size: 16),
                      label: const Text('Retry Analysis'),
                    ),
                  ),
                if (onSwitchToManual != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onSwitchToManual,
                      icon: const Icon(Symbols.edit_note_rounded, size: 16),
                      label: const Text('Manual Input'),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Advisory Notice
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Symbols.info_rounded,
                size: 16,
                color: Color(0xFF074E95),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI suggestions are advisory only. Permanent-way staff must inspect and confirm the actual hazard and required action.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
