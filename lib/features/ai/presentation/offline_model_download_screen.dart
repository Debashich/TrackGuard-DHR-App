import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/ai_provider_config.dart';
import '../domain/ai_service_provider.dart';
import '../domain/offline_model_manager.dart';
import '../domain/offline_model_state.dart';

class OfflineModelDownloadScreen extends ConsumerStatefulWidget {
  const OfflineModelDownloadScreen({super.key});

  @override
  ConsumerState<OfflineModelDownloadScreen> createState() =>
      _OfflineModelDownloadScreenState();
}

class _OfflineModelDownloadScreenState
    extends ConsumerState<OfflineModelDownloadScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modelStateAsync = ref.watch(offlineModelStateProvider);
    final manager = ref.read(offlineModelManagerProvider);
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? false;

    final state =
        modelStateAsync.value ??
        const OfflineModelState(
          status: OfflineModelStatus.checking,
          modelName: AiProviderConfig.offlineGemmaModelName,
          modelId: AiProviderConfig.offlineGemmaSlug,
        );

    final downloadSettings = manager.getDownloadSettings();

    return PopScope(
      canPop: !state.isDownloading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showExitConfirmationDialog(context, l10n);
        if (shouldLeave && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.offlinePhotoHelperPackTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Model Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAmber.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: AppTheme.primaryAmber,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.modelName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.offlineModelVersion(
                                  state.version ?? '1.0.0',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(state.status, l10n),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.offlineModelOfflineNotice,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${l10n.offlinePhotoHelperPackTitle} (~2.6 GB)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.offlinePhotoHelperPackSubtitle),
                  const SizedBox(height: 8),
                  const Text(
                    'Please keep at least 4 GB of free storage available.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  if (state.isDownloading) LinearProgressIndicator(value: state.progressPercent / 100),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Network & Download Preferences Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.downloadPreferencesHeading,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryAmber,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.offlineModelWifiOnly,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        l10n.preventsCellularUsage,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      value: downloadSettings.wifiOnly,
                      activeThumbColor: AppTheme.primaryAmber,
                      onChanged: state.isDownloading
                          ? null
                          : (val) async {
                              await manager.setDownloadSettings(
                                downloadSettings.copyWith(
                                  wifiOnly: val,
                                  allowCellularDownload: !val,
                                ),
                              );
                              setState(() {});
                            },
                    ),
                    if (!downloadSettings.wifiOnly) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.statusOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.statusOrange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.statusOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.offlineModelMobileDataWarning,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.statusOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Download Status & Progress Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.modelStatusAndActionsHeading,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryAmber,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Progress section if downloading
                    if (state.isDownloading) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.offlineModelDownloading,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${state.progressPercent}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: state.progress > 0 ? state.progress : null,
                          backgroundColor: AppTheme.surfaceDarkElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryAmber,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.offlineModelDownloadProgress(
                          state.formattedDownloadedSize,
                          state.formattedTotalSize,
                          state.progressPercent,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.statusRed,
                            side: const BorderSide(color: AppTheme.statusRed),
                          ),
                          onPressed: () async {
                            await manager.cancelDownload();
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(l10n.offlineModelCancelDownload),
                        ),
                      ),
                    ] else if (state.status ==
                        OfflineModelStatus.initializing) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryAmber,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Initializing Gemma 4 E2B runtime context...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (state.isReady) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.statusGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.statusGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.statusGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.offlineModelReady,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.statusGreen,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (state.downloadedAt != null)
                                    Text(
                                      l10n.offlineModelDownloadedAt(
                                        '${state.downloadedAt!.day}/${state.downloadedAt!.month}/${state.downloadedAt!.year}',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
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
                    ] else if (state.status ==
                        OfflineModelStatus.downloaded) ...[
                      Text(
                        l10n.offlineModelDownloaded,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    await manager.initialize();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Initialization failed: $e',
                                          ),
                                          backgroundColor: AppTheme.statusRed,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: Text(l10n.offlineModelActivate),
                        ),
                      ),
                    ] else ...[
                      // Not downloaded or failed
                      if (state.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.statusRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.statusRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.statusRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.statusRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (!isOnline) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.offlineModelNetworkRequired,
                                        ),
                                        backgroundColor: AppTheme.statusOrange,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isLoading = true);
                                  try {
                                    await manager.download();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Download error: $e'),
                                          backgroundColor: AppTheme.statusRed,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: Text(l10n.downloadOnWifiButton),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OfflineModelStatus status, AppLocalizations l10n) {
    Color color;
    String label;

    switch (status) {
      case OfflineModelStatus.ready:
        color = AppTheme.statusGreen;
        label = l10n.offlineModelReady;
        break;
      case OfflineModelStatus.downloaded:
        color = AppTheme.statusBlue;
        label = l10n.offlineModelDownloaded;
        break;
      case OfflineModelStatus.downloading:
        color = AppTheme.primaryAmber;
        label = l10n.offlineModelDownloading;
        break;
      case OfflineModelStatus.initializing:
        color = AppTheme.primaryAmber;
        label = l10n.offlineModelInitializing;
        break;
      case OfflineModelStatus.failed:
        color = AppTheme.statusRed;
        label = l10n.offlineModelFailed;
        break;
      case OfflineModelStatus.checking:
        color = AppTheme.textSecondary;
        label = 'Checking...';
        break;
      case OfflineModelStatus.unsupported:
        color = AppTheme.statusRed;
        label = l10n.offlineModelUnsupported;
        break;
      case OfflineModelStatus.corrupted:
        color = AppTheme.statusRed;
        label = 'Corrupted';
        break;
      case OfflineModelStatus.notDownloaded:
        color = AppTheme.textSecondary;
        label = l10n.offlineModelNotDownloaded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(l10n.offlineModelDownloadInProgress),
            content: Text(
              l10n.cancelDownloadConfirmation,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.stayOnPage),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.cancelDownloadAndLeave),
              ),
            ],
          ),
        ) ??
        false;
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.offlineModelDeleteConfirmation,
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.statusGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.offlineModelReportsRemainSafe,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.statusGreen,
                ),
              ),
            ),
          ],
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

    if (confirm == true && context.mounted) {
      try {
        await manager.deleteModel();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.offlineModelDeleted),
              backgroundColor: AppTheme.statusGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete model: $e'),
              backgroundColor: AppTheme.statusRed,
            ),
          );
        }
      }
    }
  }
}

