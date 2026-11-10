import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/trackguard_dialog.dart';
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

  // Palette aligned with the Home screen and Inspection Details screen design.
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _ink = Color(0xFF0F172A);
  static const Color _navy = Color(0xFF0A1E3F);
  static const Color _blue = Color(0xFF074E95); // Home screen primary DHR blue
  static const Color _blueSoft = Color(0xFFEBF3FC); // Home screen soft blue container
  static const Color _border = Color(0xFFE2E8F0); // Home screen border
  static const Color _secondary = Color(0xFF64748B); // Home screen secondary slate text

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modelStateAsync = ref.watch(offlineModelStateProvider);
    final manager = ref.read(offlineModelManagerProvider);
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? false;

    final state = modelStateAsync.value ??
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
        if (shouldLeave && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () async {
              if (state.isDownloading) {
                final shouldLeave =
                    await _showExitConfirmationDialog(context, l10n);
                if (shouldLeave && context.mounted) context.pop();
              } else {
                context.pop();
              }
            },
            icon: const Icon(
              Symbols.arrow_back_rounded,
              color: _ink,
              size: 22,
            ),
            tooltip: 'Back',
          ),
          title: Text(
            l10n.offlinePhotoHelperPackTitle,
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _buildHero(state, l10n),
            const SizedBox(height: 18),
            _buildStoragePanel(),
            const SizedBox(height: 16),
            Text(
              l10n.downloadPreferencesHeading,
              style: const TextStyle(
                color: _blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.65,
              ),
            ),
            const SizedBox(height: 8),
            _buildWifiPanel(
              downloadSettings: downloadSettings,
              isDownloading: state.isDownloading,
              l10n: l10n,
              manager: manager,
            ),
            if (!downloadSettings.wifiOnly) ...[
              const SizedBox(height: 8),
              _buildMobileDataWarning(l10n),
            ],
            const SizedBox(height: 16),
            _buildStatusAndActions(
              context: context,
              state: state,
              l10n: l10n,
              manager: manager,
              isOnline: isOnline,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(OfflineModelState state, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _blueSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Symbols.layers_rounded,
            size: 34,
            color: _blue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          state.modelName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.offlinePhotoHelperPackTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _secondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _blueSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.cloud_download_rounded, color: _blue, size: 16),
              SizedBox(width: 6),
              Text(
                'AI Model',
                style: TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.offlineModelOfflineNotice,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.offlineModelVersion(state.version ?? '1.0.0'),
          style: const TextStyle(
            color: _secondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        _buildStatusBadge(state.status, l10n),
      ],
    );
  }

  Widget _buildStoragePanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: _panelDecoration(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStorageMetric(
              icon: Symbols.storage_rounded,
              label: 'Download Size',
              value: '~2.6 GB',
            ),
          ),
          Container(
            width: 1.2,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: _border,
          ),
          Expanded(
            child: _buildStorageMetric(
              icon: Symbols.smartphone_rounded,
              label: 'Required Free Space',
              value: '≥ 4 GB',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _blueSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _blue, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _secondary,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWifiPanel({
    required dynamic downloadSettings,
    required bool isDownloading,
    required AppLocalizations l10n,
    required OfflineModelManager manager,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: _panelDecoration(radius: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.wifi_rounded, color: _blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.offlineModelWifiOnly,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.preventsCellularUsage,
                  style: const TextStyle(
                    color: _secondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Switch.adaptive(
            value: downloadSettings.wifiOnly,
            activeThumbColor: Colors.white,
            activeTrackColor: _blue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFB8C5D5),
            onChanged: isDownloading
                ? null
                : (value) async {
                    await manager.setDownloadSettings(
                      downloadSettings.copyWith(
                        wifiOnly: value,
                        allowCellularDownload: !value,
                      ),
                    );
                    if (mounted) setState(() {});
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDataWarning(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2D4B4)),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.warning_amber_rounded,
            color: Color(0xFFC77725),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.offlineModelMobileDataWarning,
              style: const TextStyle(
                color: Color(0xFF9A5A1D),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndActions({
    required BuildContext context,
    required OfflineModelState state,
    required AppLocalizations l10n,
    required OfflineModelManager manager,
    required bool isOnline,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.modelStatusAndActionsHeading,
            style: const TextStyle(
              color: _blue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.65,
            ),
          ),
          const SizedBox(height: 12),
          if (state.isDownloading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.offlineModelDownloading,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${state.progressPercent}%',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: state.progress > 0 ? state.progress : null,
                minHeight: 6,
                backgroundColor: _blueSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(_blue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.offlineModelDownloadProgress(
                state.formattedDownloadedSize,
                state.formattedTotalSize,
                state.progressPercent,
              ),
              style: const TextStyle(color: _secondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _outlinedActionButton(
              label: l10n.offlineModelCancelDownload,
              icon: Symbols.close_rounded,
              color: AppTheme.statusRed,
              onPressed: () async {
                ScaffoldMessenger.of(context).clearSnackBars();
                await manager.cancelDownload();
              },
            ),
          ] else if (state.status == OfflineModelStatus.initializing) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_blue),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Initializing Gemma 4 E2B runtime context...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _secondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (state.isReady) ...[
            _buildReadyNotice(state, l10n),
            const SizedBox(height: 12),
            _outlinedActionButton(
              label: l10n.offlineModelDelete,
              icon: Symbols.delete_outline_rounded,
              color: AppTheme.statusRed,
              onPressed: () => _confirmAndDeleteModel(context, manager, l10n),
            ),
          ] else if (state.status == OfflineModelStatus.downloaded) ...[
            Text(
              l10n.offlineModelDownloaded,
              style: const TextStyle(color: _secondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _primaryActionButton(
              label: l10n.offlineModelActivate,
              icon: Symbols.play_arrow_rounded,
              isLoading: _isLoading,
              onPressed: _isLoading
                  ? null
                  : () => _initializeModel(context, manager),
            ),
          ] else ...[
            if (state.errorMessage != null) ...[
              _buildErrorNotice(state.errorMessage!),
              const SizedBox(height: 12),
            ],
            _primaryActionButton(
              label: l10n.downloadOnWifiButton,
              icon: Symbols.download_rounded,
              isLoading: _isLoading,
              onPressed: _isLoading
                  ? null
                  : () => _downloadModel(context, manager, l10n, isOnline),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadyNotice(OfflineModelState state, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.statusGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statusGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.check_circle_rounded,
            color: AppTheme.statusGreen,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.offlineModelReady,
                  style: const TextStyle(
                    color: AppTheme.statusGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (state.downloadedAt != null)
                  Text(
                    l10n.offlineModelDownloadedAt(
                      '${state.downloadedAt!.day}/${state.downloadedAt!.month}/${state.downloadedAt!.year}',
                    ),
                    style: const TextStyle(color: _secondary, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorNotice(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.statusRed.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statusRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.error_outline_rounded,
            color: AppTheme.statusRed,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.statusRed,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _blue.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _outlinedActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.65)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration({double radius = 16}) {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    OfflineModelStatus status,
    AppLocalizations l10n,
  ) {
    late final Color color;
    late final String label;

    switch (status) {
      case OfflineModelStatus.ready:
        color = AppTheme.statusGreen;
        label = l10n.offlineModelReady;
        break;
      case OfflineModelStatus.downloaded:
        color = AppTheme.statusGreen;
        label = l10n.offlineModelDownloaded;
        break;
      case OfflineModelStatus.downloading:
        color = _blue;
        label = l10n.offlineModelDownloading;
        break;
      case OfflineModelStatus.initializing:
        color = _blue;
        label = l10n.offlineModelInitializing;
        break;
      case OfflineModelStatus.failed:
        color = AppTheme.statusRed;
        label = l10n.offlineModelFailed;
        break;
      case OfflineModelStatus.checking:
        color = _secondary;
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
        color = AppTheme.statusRed;
        label = l10n.offlineModelNotDownloaded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _initializeModel(
    BuildContext context,
    OfflineModelManager manager,
  ) async {
    setState(() => _isLoading = true);
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadModel(
    BuildContext context,
    OfflineModelManager manager,
    AppLocalizations l10n,
    bool isOnline,
  ) async {
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.offlineModelNetworkRequired),
          backgroundColor: const Color(0xFFC77725),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await manager.download();
    } on OfflineModelDownloadCancelledException {
      // User cancelled download cleanly
    } catch (e) {
      if (!context.mounted) return;
      final currentStatus = ref.read(offlineModelStateProvider).value?.status;
      if (currentStatus == OfflineModelStatus.notDownloaded) {
        // Download was cancelled by user
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download error: $e'),
          backgroundColor: AppTheme.statusRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showExitConfirmationDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => TrackGuardDialog(
            icon: Symbols.cancel_rounded,
            isDestructive: true,
            title: l10n.offlineModelDownloadInProgress,
            message: l10n.cancelDownloadConfirmation,
            primaryLabel: l10n.cancelDownloadAndLeave,
            primaryIcon: Symbols.close_rounded,
            onPrimaryPressed: () => Navigator.of(ctx).pop(true),
            cancelLabel: l10n.stayOnPage,
            onCancelPressed: () => Navigator.of(ctx).pop(false),
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
      builder: (ctx) => TrackGuardDialog(
        icon: Symbols.delete_forever_rounded,
        isDestructive: true,
        title: l10n.offlineModelDeleteTitle,
        message: l10n.offlineModelDeleteConfirmation,
        content: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TrackGuardDialog.greenSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Symbols.shield_rounded,
                size: 16,
                color: TrackGuardDialog.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.offlineModelReportsRemainSafe,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TrackGuardDialog.green,
                  ),
                ),
              ),
            ],
          ),
        ),
        primaryLabel: l10n.offlineModelDelete,
        primaryIcon: Symbols.delete_outline_rounded,
        onPrimaryPressed: () => Navigator.of(ctx).pop(true),
        cancelLabel: 'Cancel',
        onCancelPressed: () => Navigator.of(ctx).pop(false),
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
