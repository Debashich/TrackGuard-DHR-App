import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/localization/l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/ai_provider_config.dart';
import '../domain/ai_service_provider.dart';
import '../domain/ai_settings.dart';

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);

    final isOfflineReadyAsync = ref.watch(isAiModelReadyProvider);
    final isOfflineReady = isOfflineReadyAsync.value ?? false;

    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? false;

    final currentLang = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // AI Mode Selection Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        size: 20,
                        color: AppTheme.primaryAmber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aiSettingsTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryAmber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildModeOption(
                    context,
                    title: l10n.aiModeAutomatic,
                    subtitle: l10n.aiOfflineFirstNotice,
                    mode: AiMode.automatic,
                    currentMode: settings.mode,
                    onSelected: (mode) => settingsNotifier.setMode(mode),
                  ),
                  const Divider(height: 16),
                  _buildModeOption(
                    context,
                    title: l10n.aiModeOfflineGemma,
                    subtitle: isOfflineReady
                        ? l10n.aiGemmaReady
                        : l10n.aiGemmaUnavailable,
                    mode: AiMode.offlineGemma,
                    currentMode: settings.mode,
                    onSelected: (mode) => settingsNotifier.setMode(mode),
                  ),
                  const Divider(height: 16),
                  _buildModeOption(
                    context,
                    title: l10n.aiModeOnlineGemini,
                    subtitle: isOnline
                        ? l10n.aiGemini
                        : l10n.aiGeminiRequiresNetwork,
                    mode: AiMode.onlineGemini,
                    currentMode: settings.mode,
                    onSelected: (mode) => settingsNotifier.setMode(mode),
                  ),
                  const Divider(height: 16),
                  _buildModeOption(
                    context,
                    title: l10n.aiModeManual,
                    subtitle: l10n.aiManualClassification,
                    mode: AiMode.manual,
                    currentMode: settings.mode,
                    onSelected: (mode) => settingsNotifier.setMode(mode),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Offline Gemma 4 E2B Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        size: 20,
                        color: AppTheme.primaryAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.aiOfflineGemma.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        label: isOfflineReady
                            ? l10n.aiGemmaReady
                            : l10n.aiGemmaUnavailable,
                        color: isOfflineReady
                            ? AppTheme.statusGreen
                            : AppTheme.statusOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: l10n.aiModelName,
                    value: AiProviderConfig.offlineGemmaModelName,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    label: l10n.aiPromptLanguage,
                    value: currentLang.displayName,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.aiPrivacyNotice,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      return OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l10n.aiGemmaLoading),
                        onPressed: () async {
                          final service = ref.read(aiAnalysisServiceProvider);
                          await service.initializeOfflineModel();
                          ref.invalidate(isAiModelReadyProvider);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Online Gemini Backend Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_rounded,
                        size: 20,
                        color: AppTheme.statusBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.aiGemini.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.statusBlue,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        label: isOnline ? 'Online Ready' : 'Network Required',
                        color: isOnline
                            ? AppTheme.statusGreen
                            : AppTheme.statusRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: l10n.aiModelName,
                    value: AiProviderConfig.onlineGeminiModelLabel,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    label: 'Integration',
                    value: 'Supabase Edge Function (Zero Client Keys)',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.aiGeminiRequiresNetwork,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mandatory Human Confirmation Advisory Card
          Card(
            color: AppTheme.surfaceDarkElevated,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppTheme.primaryAmber,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aiHumanConfirmationRequired,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.aiAdvisoryNotice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required AiMode mode,
    required AiMode currentMode,
    required ValueChanged<AiMode> onSelected,
  }) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: () => onSelected(mode),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryAmber : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
