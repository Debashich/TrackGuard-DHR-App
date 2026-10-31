import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/localization/l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/ai_provider_config.dart';
import '../domain/ai_service_provider.dart';
import '../domain/ai_settings.dart';
import '../domain/offline_model_manager.dart';
import '../domain/offline_model_state.dart';

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(aiSettingsProvider);
    final settingsNotifier = ref.read(aiSettingsProvider.notifier);

    final modelStateAsync = ref.watch(offlineModelStateProvider);
    final manager = ref.read(offlineModelManagerProvider);
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? false;

    final currentLang = ref.watch(appLanguageProvider);

    final modelState =
        modelStateAsync.value ??
        const OfflineModelState(
          status: OfflineModelStatus.checking,
          modelName: AiProviderConfig.offlineGemmaModelName,
          modelId: AiProviderConfig.offlineGemmaSlug,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Photo Helper')),
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
                    title: 'Automatic Photo Helper (Recommended)',
                    subtitle: 'Suggests a hazard type and note from your photo, online or offline.',
                    mode: AiMode.automatic,
                    currentMode: settings.mode,
                    onSelected: (mode) => settingsNotifier.setMode(mode),
                  ),
                  const Divider(height: 16),
                  _buildModeOption(
                    context,
                    title: 'Manual Only',
                    subtitle: 'Turn off photo suggestions; I will choose the hazard myself.',
                    mode: AiMode.manual,
                    currentMode: settings.mode,
                    onSelected: (mode) => settingsNotifier.setMode(mode),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Offline Gemma 4 E2B Model Management Card
          _buildGemmaManagementCard(
            context,
            ref,
            modelState,
            manager,
            currentLang,
            l10n,
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
                      color: AppTheme.textSecondary,
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
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.aiAdvisoryNotice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
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

  Widget _buildGemmaManagementCard(
    BuildContext context,
    WidgetRef ref,
    OfflineModelState modelState,
    OfflineModelManager manager,
    dynamic currentLang,
    AppLocalizations l10n,
  ) {
    Color badgeColor;
    String badgeLabel;

    switch (modelState.status) {
      case OfflineModelStatus.ready:
        badgeColor = AppTheme.statusGreen;
        badgeLabel = l10n.offlineModelReady;
        break;
      case OfflineModelStatus.downloaded:
        badgeColor = AppTheme.statusBlue;
        badgeLabel = l10n.offlineModelDownloaded;
        break;
      case OfflineModelStatus.downloading:
        badgeColor = AppTheme.primaryAmber;
        badgeLabel = l10n.offlineModelDownloading;
        break;
      case OfflineModelStatus.initializing:
        badgeColor = AppTheme.primaryAmber;
        badgeLabel = l10n.offlineModelInitializing;
        break;
      case OfflineModelStatus.failed:
        badgeColor = AppTheme.statusRed;
        badgeLabel = l10n.offlineModelFailed;
        break;
      case OfflineModelStatus.checking:
        badgeColor = AppTheme.textSecondary;
        badgeLabel = 'Checking...';
        break;
      case OfflineModelStatus.unsupported:
        badgeColor = AppTheme.statusRed;
        badgeLabel = l10n.offlineModelUnsupported;
        break;
      case OfflineModelStatus.corrupted:
        badgeColor = AppTheme.statusRed;
        badgeLabel = 'Corrupted';
        break;
      case OfflineModelStatus.notDownloaded:
        badgeColor = AppTheme.textSecondary;
        badgeLabel = l10n.offlineModelNotDownloaded;
        break;
    }

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
                _buildStatusBadge(label: badgeLabel, color: badgeColor),
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
            const SizedBox(height: 8),
            _buildInfoRow(
              label: 'Source',
              value: 'Hugging Face (${AiProviderConfig.offlineGemmaRepository})',
            ),

            // State specific contents
            if (modelState.status == OfflineModelStatus.ready) ...[
              const SizedBox(height: 8),
              if (modelState.downloadedAt != null)
                _buildInfoRow(
                  label: 'Installed Date',
                  value:
                      '${modelState.downloadedAt!.day}/${modelState.downloadedAt!.month}/${modelState.downloadedAt!.year}',
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.statusRed,
                    side: const BorderSide(color: AppTheme.statusRed),
                  ),
                  onPressed: () =>
                      _confirmAndDeleteModel(context, manager, l10n),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.offlineModelDelete),
                ),
              ),
            ] else if (modelState.status == OfflineModelStatus.downloaded) ...[
              const SizedBox(height: 10),
              Text(
                l10n.offlineModelDownloaded,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      await manager.initialize();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Initialization failed: $e'),
                            backgroundColor: AppTheme.statusRed,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(l10n.offlineModelActivate),
                ),
              ),
            ] else if (modelState.status == OfflineModelStatus.downloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: modelState.progress > 0 ? modelState.progress : null,
                backgroundColor: AppTheme.surfaceDarkElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryAmber,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${modelState.formattedDownloadedSize} / ${modelState.formattedTotalSize}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${modelState.progressPercent}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.statusRed,
                    side: const BorderSide(color: AppTheme.statusRed),
                  ),
                  onPressed: () => manager.cancelDownload(),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.offlineModelCancelDownload),
                ),
              ),
            ] else if (modelState.status == OfflineModelStatus.failed) ...[
              const SizedBox(height: 10),
              Text(
                modelState.errorMessage ?? l10n.offlineModelDownloadFailed,
                style: const TextStyle(fontSize: 12, color: AppTheme.statusRed),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.push('/settings/ai/download'),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.offlineModelRetryDownload),
                ),
              ),
            ] else ...[
              // Not downloaded
              const SizedBox(height: 10),
              Text(
                '${l10n.offlineModelNotDownloaded}. ${l10n.offlineModelApproximateSize('~1.2 GB')}.',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.push('/settings/ai/download'),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(l10n.offlineModelDownload),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteModel(
    BuildContext context,
    OfflineModelManager manager,
    AppLocalizations l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(l10n.offlineModelDeleteTitle),
        content: Text(
          l10n.offlineModelDeleteConfirmation,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.offlineModelDelete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await manager.deleteModel();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.offlineModelDeleted),
            backgroundColor: AppTheme.statusGreen,
          ),
        );
      }
    }
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
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.borderDark,
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
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
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

