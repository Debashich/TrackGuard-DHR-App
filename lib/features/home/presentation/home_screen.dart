import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/localization/l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/widgets/connectivity_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../ai/domain/ai_service_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reports/domain/report_repository_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? false;
    final pendingCountAsync = ref.watch(pendingReportsCountProvider);
    final pendingCount = pendingCountAsync.value ?? 0;
    final isAiReadyAsync = ref.watch(isAiModelReadyProvider);
    final isAiReady = isAiReadyAsync.value ?? false;
    final currentLang = ref.watch(appLanguageProvider);

    final sectionName = user?.assignedSection != null
        ? DhrWaypoints.getSectionName(user!.assignedSection!)
        : l10n.unassignedSection;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // Language selector
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language, color: AppTheme.primaryAmber),
            tooltip: l10n.selectLanguage,
            onSelected: (lang) {
              ref.read(appLanguageProvider.notifier).setLanguage(lang);
            },
            itemBuilder: (context) => AppLanguage.values.map((lang) {
              final isSelected = lang == currentLang;
              return PopupMenuItem<AppLanguage>(
                value: lang,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppTheme.primaryAmber,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(lang.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingReportsCountProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connectivity & AI status row
                Row(
                  children: [
                    Expanded(child: ConnectivityIndicator(isOnline: isOnline)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAiReady ? Icons.psychology : Icons.bolt,
                            size: 14,
                            color: isAiReady
                                ? AppTheme.statusGreen
                                : AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAiReady ? 'AI: Gemma' : 'AI: Heuristic',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gangman profile & Section card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryAmber.withValues(
                                alpha: 0.2,
                              ),
                              radius: 22,
                              child: const Icon(
                                Icons.engineering,
                                color: AppTheme.primaryAmber,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Gangman',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAmber.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.gangman.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryAmber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.alt_route,
                              size: 16,
                              color: AppTheme.primaryAmber,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.assignedSection(sectionName),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Primary Action: NEW REPORT
                PrimaryButton(
                  text: l10n.newReport.toUpperCase(),
                  icon: Icons.camera_alt,
                  onPressed: () => context.push('/gangman/report/capture'),
                ),
                const SizedBox(height: 16),

                // Pending reports queue card
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/gangman/reports'),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: AppTheme.primaryAmber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.pendingQueue,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.pendingReportsCount(pendingCount),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: pendingCount > 0
                                        ? AppTheme.primaryAmber
                                        : Colors.white60,
                                    fontWeight: pendingCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Offline Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'FIELD OPERATIONS NOTICE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryAmber.withValues(
                                alpha: 0.9,
                              ),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.offlineExplanation,
                        style: const TextStyle(
                          fontSize: 13,
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
      ),
    );
  }
}
