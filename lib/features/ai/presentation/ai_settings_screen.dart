import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/trackguard_dialog.dart';
import '../../../core/connectivity/connectivity_provider.dart';
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

    final modelState =
        modelStateAsync.value ??
        const OfflineModelState(
          status: OfflineModelStatus.checking,
          modelName: AiProviderConfig.offlineGemmaModelName,
          modelId: AiProviderConfig.offlineGemmaSlug,
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            l10n.smartPhotoHelperTitle,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A1E3F),
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF0A1E3F),
            ),
            tooltip: l10n.navigationBack,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/gangman/home');
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 14.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. AI & Model Settings Card (Mockup Design)
                _buildModeSettingsCard(
                  context,
                  settings: settings,
                  settingsNotifier: settingsNotifier,
                  isOnline: isOnline,
                  l10n: l10n,
                ),
                const SizedBox(height: 14),

                // 2. Offline Model Card (Mockup Design)
                _buildOfflineModelCard(
                  context,
                  ref: ref,
                  modelState: modelState,
                  manager: manager,
                  l10n: l10n,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSettingsCard(
    BuildContext context, {
    required AiSettings settings,
    required AiSettingsNotifier settingsNotifier,
    required bool isOnline,
    required AppLocalizations l10n,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Icon + "AI & Model Settings"
          Row(
            children: [
              const Icon(
                Symbols.tune_rounded,
                color: Color(0xFF074E95),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.aiSettingsTitle,
                style: const TextStyle(
                  color: Color(0xFF0A1E3F),
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Option 1: Automatic Photo Helper
          _buildSelectableOption(
            title: l10n.aiModeAutomaticHelper
                .replaceFirst(' (Recommended)', '\n(Recommended)'),
            subtitle: l10n.aiModeAutomaticHelperDesc,
            icon: Symbols.auto_awesome_rounded,
            mode: AiMode.automatic,
            currentMode: settings.mode,
            onSelected: (mode) => settingsNotifier.setMode(mode),
          ),
          const SizedBox(height: 10),

          // Option 2: Online Photo Helper
          _buildSelectableOption(
            title: l10n.aiModeOnlineHelper,
            subtitle: l10n.aiModeOnlineHelperDesc,
            icon: Symbols.cloud_rounded,
            mode: AiMode.onlineGemini,
            currentMode: settings.mode,
            onSelected: (mode) => settingsNotifier.setMode(mode),
            badge: _buildOnlineStatusBadge(isOnline: isOnline),
          ),
          const SizedBox(height: 10),

          // Option 3: Offline Photo Helper
          _buildSelectableOption(
            title: l10n.aiModeOfflineHelper,
            subtitle: l10n.aiModeOfflineHelperDesc,
            icon: Symbols.download_rounded,
            mode: AiMode.offlineGemma,
            currentMode: settings.mode,
            onSelected: (mode) => settingsNotifier.setMode(mode),
          ),
          const SizedBox(height: 10),

          // Option 4: Manual Only
          _buildSelectableOption(
            title: l10n.aiModeManualOnly,
            subtitle: l10n.aiModeManualOnlyDesc,
            icon: Symbols.touch_app_rounded,
            mode: AiMode.manual,
            currentMode: settings.mode,
            onSelected: (mode) => settingsNotifier.setMode(mode),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required AiMode mode,
    required AiMode currentMode,
    required ValueChanged<AiMode> onSelected,
    Widget? badge,
  }) {
    final isSelected = mode == currentMode;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF074E95)
              : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(mode),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 10.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Radio Indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF074E95)
                          : const Color(0xFFCBD5E1),
                      width: 2.0,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF074E95),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),

                // Icon Box
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: const Color(0xFF074E95),
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Title, Badge & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                                height: 1.25,
                              ),
                              maxLines: mode == AiMode.automatic ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            badge,
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatusBadge({required bool isOnline}) {
    final color = isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final bgColor =
        isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final borderColor =
        isOnline ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline
                ? Symbols.check_circle_rounded
                : Symbols.cancel_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isOnline ? 'Ready' : 'Not Ready',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineModelCard(
    BuildContext context, {
    required WidgetRef ref,
    required OfflineModelState modelState,
    required OfflineModelManager manager,
    required AppLocalizations l10n,
  }) {
    Color badgeColor;
    Color badgeBgColor;
    Color badgeBorderColor;
    String badgeLabel;
    IconData badgeIcon = Symbols.check_circle_rounded;

    switch (modelState.status) {
      case OfflineModelStatus.ready:
        badgeColor = const Color(0xFF16A34A);
        badgeBgColor = const Color(0xFFDCFCE7);
        badgeBorderColor = const Color(0xFF86EFAC);
        badgeLabel = 'Gemma 4 E2B ready';
        badgeIcon = Symbols.check_circle_rounded;
        break;
      case OfflineModelStatus.downloaded:
        badgeColor = const Color(0xFF16A34A);
        badgeBgColor = const Color(0xFFDCFCE7);
        badgeBorderColor = const Color(0xFF86EFAC);
        badgeLabel = 'Gemma 4 E2B downloaded';
        badgeIcon = Symbols.check_circle_rounded;
        break;
      case OfflineModelStatus.downloading:
        badgeColor = AppTheme.primaryAmber;
        badgeBgColor = const Color(0xFFFEF3C7);
        badgeBorderColor = const Color(0xFFFCD34D);
        badgeLabel = 'Downloading (${modelState.progressPercent}%)';
        badgeIcon = Symbols.sync_rounded;
        break;
      case OfflineModelStatus.initializing:
        badgeColor = AppTheme.primaryAmber;
        badgeBgColor = const Color(0xFFFEF3C7);
        badgeBorderColor = const Color(0xFFFCD34D);
        badgeLabel = 'Activating...';
        badgeIcon = Symbols.sync_rounded;
        break;
      case OfflineModelStatus.failed:
        badgeColor = const Color(0xFFDC2626);
        badgeBgColor = const Color(0xFFFEE2E2);
        badgeBorderColor = const Color(0xFFFCA5A5);
        badgeLabel = 'Failed';
        badgeIcon = Symbols.error_rounded;
        break;
      case OfflineModelStatus.checking:
        badgeColor = const Color(0xFF64748B);
        badgeBgColor = const Color(0xFFF1F5F9);
        badgeBorderColor = const Color(0xFFE2E8F0);
        badgeLabel = 'Checking...';
        badgeIcon = Symbols.sync_rounded;
        break;
      case OfflineModelStatus.unsupported:
      case OfflineModelStatus.corrupted:
        badgeColor = const Color(0xFFDC2626);
        badgeBgColor = const Color(0xFFFEE2E2);
        badgeBorderColor = const Color(0xFFFCA5A5);
        badgeLabel = 'Corrupted';
        badgeIcon = Symbols.error_rounded;
        break;
      case OfflineModelStatus.notDownloaded:
        badgeColor = const Color(0xFFDC2626);
        badgeBgColor = const Color(0xFFFEE2E2);
        badgeBorderColor = const Color(0xFFFCA5A5);
        badgeLabel = 'Not downloaded';
        badgeIcon = Symbols.info_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Icon + "Offline Model" ... [Badge]
          Row(
            children: [
              const Icon(
                Symbols.memory_rounded,
                color: Color(0xFF074E95),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Offline Model',
                  style: TextStyle(
                    color: Color(0xFF0A1E3F),
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeBorderColor, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        badgeIcon,
                        size: 12,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 24, thickness: 1.0),

          // Model Name Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Model Name',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                AiProviderConfig.offlineGemmaModelName,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // User-friendly Description
          Text(
            _getOfflineModelDescription(modelState.status, l10n),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Actions based on state
          if (modelState.status == OfflineModelStatus.downloaded) ...[
            // Activate button (Solid blue)
            _buildSolidBlueButton(
              icon: Icons.play_arrow,
              label: l10n.offlineModelActivate,
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
            ),
            const SizedBox(height: 12),

            // Delete button (Light red with red border)
            _buildLightRedButton(
              icon: Symbols.delete_outline_rounded,
              label: l10n.offlineModelDelete,
              onPressed: () =>
                  _confirmAndDeleteModel(context, manager, l10n),
            ),
          ] else if (modelState.status == OfflineModelStatus.ready) ...[
            // Delete button
            _buildLightRedButton(
              icon: Symbols.delete_outline_rounded,
              label: l10n.offlineModelDelete,
              onPressed: () =>
                  _confirmAndDeleteModel(context, manager, l10n),
            ),
          ] else if (modelState.status == OfflineModelStatus.downloading) ...[
            LinearProgressIndicator(
              value: modelState.progress > 0 ? modelState.progress : null,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF074E95),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${modelState.formattedDownloadedSize} / ${modelState.formattedTotalSize}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Text(
                  '${modelState.progressPercent}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF074E95),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildLightRedButton(
              icon: Icons.close,
              label: l10n.offlineModelCancelDownload,
              onPressed: () => manager.cancelDownload(),
            ),
          ] else if (modelState.status == OfflineModelStatus.failed) ...[
            _buildSolidBlueButton(
              icon: Icons.refresh,
              label: l10n.offlineModelRetryDownload,
              onPressed: () => context.push('/settings/ai/download'),
            ),
          ] else ...[
            // Not downloaded
            _buildSolidBlueButton(
              icon: Symbols.download_rounded,
              label: l10n.offlineModelDownload,
              onPressed: () => context.push('/settings/ai/download'),
            ),
          ],
        ],
      ),
    );
  }

  String _getOfflineModelDescription(
    OfflineModelStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case OfflineModelStatus.ready:
        return 'On-device AI is active. You can inspect tracks and get hazard suggestions without an internet connection.';
      case OfflineModelStatus.downloaded:
        return 'Model files are downloaded on this phone. Tap below to activate offline photo analysis.';
      case OfflineModelStatus.downloading:
        return 'Downloading offline AI files. Please keep the app open until download completes.';
      case OfflineModelStatus.initializing:
        return 'Activating offline model... this will take a moment.';
      case OfflineModelStatus.failed:
        return 'Download failed. Please check your connection and tap retry below.';
      case OfflineModelStatus.corrupted:
      case OfflineModelStatus.unsupported:
        return 'Model files appear corrupted. Please delete and re-download.';
      case OfflineModelStatus.checking:
        return 'Checking model status...';
      case OfflineModelStatus.notDownloaded:
        return 'Download the offline model (~1.2 GB) once to enable track defect suggestions without network coverage.';
    }
  }

  Widget _buildSolidBlueButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF074E95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF074E95).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLightRedButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFFDC2626), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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
      builder: (ctx) => TrackGuardDialog(
        icon: Icons.delete_forever_rounded,
        isDestructive: true,
        title: l10n.offlineModelDeleteTitle,
        message: l10n.offlineModelDeleteConfirmation,
        primaryLabel: l10n.offlineModelDelete,
        primaryIcon: Icons.delete_outline_rounded,
        onPrimaryPressed: () => Navigator.of(ctx).pop(true),
        cancelLabel: 'Cancel',
        onCancelPressed: () => Navigator.of(ctx).pop(false),
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
}
