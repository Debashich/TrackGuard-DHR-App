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
    final syncSummary = ref.watch(syncSummaryProvider);
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
            icon: const Icon(Icons.person_outline),
            tooltip: l10n.navigationProfile,
            onPressed: () => context.push('/profile'),
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
                ConnectivityIndicator(isOnline: isOnline),
                const SizedBox(height: 12),

                // Gangman profile & Section card
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/profile'),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryAmber
                                    .withValues(alpha: 0.2),
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
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (user?.email != null)
                                      Text(
                                        user!.email,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
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
                              Expanded(
                                child: Text(
                                  l10n.assignedSection(sectionName),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  color: AppTheme.primaryBlue,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/gangman/report/capture'),
                    child: SizedBox(
                      height: 230,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 58,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              l10n.newReport.toUpperCase(),
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Take a photo of a slip, rockfall, drain, or track issue',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              syncSummary.pendingCount > 0
                                  ? Icons.schedule
                                  : Icons.check_circle,
                              color: syncSummary.pendingCount > 0
                                  ? AppTheme.statusAmber
                                  : AppTheme.statusGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.pendingQueue,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          syncSummary.pendingCount > 0
                              ? 'Will send automatically at next station signal'
                              : 'Your latest reports have reached the supervisor.',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (syncSummary.pendingCount > 0 &&
                                isOnline &&
                                !syncSummary.isSyncing)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final service = ref.read(
                                      reportSyncServiceProvider,
                                    );
                                    if (service != null) {
                                      try {
                                        await service.syncPendingReports();
                                        ref.invalidate(
                                          pendingReportsCountProvider,
                                        );
                                      } catch (_) {}
                                    }
                                  },
                                  child: const Text('Send Now'),
                                ),
                              ),
                            if (syncSummary.pendingCount > 0 &&
                                isOnline &&
                                !syncSummary.isSyncing)
                              const SizedBox(width: 8),
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    context.push('/gangman/reports'),
                                child: const Text('View My Reports'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
