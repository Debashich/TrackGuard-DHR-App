import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/localization/l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/severity.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/connectivity_indicator.dart';
import '../../../shared/widgets/hazard_icon.dart';
import '../../../shared/widgets/trackguard_app_bar.dart';
import '../../ai/domain/ai_service_provider.dart';
import '../../ai/domain/offline_model_state.dart';
import '../../reports/domain/report_repository_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmupOfflineModel();
    });
  }

  void _warmupOfflineModel() async {
    final manager = ref.read(offlineModelManagerProvider);
    final state = await manager.getState();
    // If the model is downloaded on disk but not yet activated, warm it up in background
    if (state.status == OfflineModelStatus.downloaded) {
      manager.initialize().catchError((error) {
        debugPrint('Dashboard offline model warm-up deferred: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? false;
    final currentLang = ref.watch(appLanguageProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: const TrackGuardAppBar(),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(localReportsProvider);
              ref.invalidate(pendingReportsCountProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 14.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConnectivityIndicator(isOnline: isOnline),
                  const SizedBox(height: 14),

                  // 1. "Report a Problem" Primary Action Button (Mockup Design)
                  _buildReportAProblemCard(context, l10n, currentLang),
                  const SizedBox(height: 14),

                  // 2. "Recent Reports" Card (Mockup Design - Top 3 Reports)
                  _buildRecentReportsCard(context, ref, l10n, currentLang),
                  const SizedBox(height: 14),

                  // 3. Emergency Control Room / Helpline Button (Mockup Design)
                  _buildEmergencyHelplineCard(context, l10n, currentLang),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportAProblemCard(
    BuildContext context,
    AppLocalizations l10n,
    AppLanguage currentLang,
  ) {
    final title = currentLang == AppLanguage.en ? 'Report a Problem' : l10n.newReport;
    final subtitle = currentLang == AppLanguage.en
        ? 'Take a photo and tell us\nwhat is wrong on the track.'
        : l10n.reportTrackHazardDescription;

    return Container(
      height: 98,
      decoration: BoxDecoration(
        color: const Color(0xFF074E95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF074E95).withValues(alpha: 0.28),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/gangman/report/capture'),
            child: Stack(
              children: [
                // Bottom-right decorative diagonal hazard stripes
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: SizedBox(
                    width: 90,
                    height: 40,
                    child: CustomPaint(
                      painter: _DiagonalStripesPainter(
                        color: const Color(0x351E88E5),
                        strokeWidth: 4.5,
                        spacing: 9.0,
                      ),
                    ),
                  ),
                ),

                // Content row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Camera with sparkles icon
                      const _CameraWithSparksIcon(),
                      const SizedBox(width: 14),

                      // Vertical divider
                      Container(
                        width: 1,
                        height: 42,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 14),

                      // Texts
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right arrow circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Symbols.arrow_forward_rounded,
                            color: Color(0xFF074E95),
                            size: 20,
                          ),
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

  Widget _buildRecentReportsCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AppLanguage currentLang,
  ) {
    final reportsAsync = ref.watch(localReportsProvider);
    final reports = reportsAsync.value ?? [];
    final sortedReports = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayReports =
        sortedReports.isNotEmpty ? sortedReports.take(3).toList() : _getSampleReports();

    final recentReportsTitle = _getRecentReportsTitle(currentLang, l10n);
    final viewAllText = _getViewAllText(currentLang, l10n);

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
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: [Icon + "Recent Reports"]  ...  ["View All →"]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const _RecentReportsHeaderIcon(),
                  const SizedBox(width: 8),
                  Text(
                    recentReportsTitle,
                    style: const TextStyle(
                      color: Color(0xFF0A1E3F),
                      fontSize: 17.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/gangman/reports'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        viewAllText,
                        style: const TextStyle(
                          color: Color(0xFF074E95),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Symbols.arrow_forward_rounded,
                        color: Color(0xFF074E95),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Top 3 Report Items
          for (int i = 0; i < displayReports.length; i++) ...[
            if (i > 0)
              const Divider(
                color: Color(0xFFF1F5F9),
                height: 20,
                thickness: 1.2,
              ),
            _buildReportRow(context, displayReports[i], l10n, currentLang),
          ],
        ],
      ),
    );
  }

  Widget _buildReportRow(
    BuildContext context,
    HazardReport report,
    AppLocalizations l10n,
    AppLanguage currentLang,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/gangman/reports/${report.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: 62x44 Thumbnail (fitted so center text has maximum width)
              _buildThumbnail(report),
              const SizedBox(width: 10),

              // Center: Title, Location, Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getReportTitle(context, report, currentLang),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.5),
                    Row(
                      children: [
                        const Icon(
                          Symbols.location_on_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _formatLocation(report),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Symbols.calendar_today_rounded,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _formatReportDate(report.createdAt, l10n),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Right: Status badge & chevron
              _buildStatusPill(report.syncStatus, l10n, currentLang),
              const SizedBox(width: 2),
              const Icon(
                Symbols.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(HazardReport report) {
    final imagePath = report.thumbnailPhotoPath ?? report.originalPhotoPath;
    final fileExists = imagePath != null && File(imagePath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 62,
        height: 44,
        child: fileExists
            ? Image.file(
                File(imagePath),
                width: 62,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallbackThumbnail(report),
              )
            : _buildFallbackThumbnail(report),
      ),
    );
  }

  Widget _buildFallbackThumbnail(HazardReport report) {
    List<Color> gradientColors;
    IconData iconData;
    Color accentColor;

    switch (report.confirmedHazardType) {
      case HazardType.vegetation:
        gradientColors = const [Color(0xFF1E3A2F), Color(0xFF2D5A46)];
        iconData = Symbols.park_rounded;
        accentColor = const Color(0xFF4ADE80);
        break;
      case HazardType.trackDefect:
        gradientColors = const [Color(0xFF1E293B), Color(0xFF334155)];
        iconData = Symbols.handyman_rounded;
        accentColor = const Color(0xFFF59E0B);
        break;
      case HazardType.slip:
      case HazardType.rockfall:
        gradientColors = const [Color(0xFF382319), Color(0xFF5A382A)];
        iconData = Symbols.landscape_rounded;
        accentColor = const Color(0xFFF87171);
        break;
      case HazardType.blockedDrain:
        gradientColors = const [Color(0xFF1E3A5F), Color(0xFF2563EB)];
        iconData = Symbols.water_drop_rounded;
        accentColor = const Color(0xFF60A5FA);
        break;
      default:
        gradientColors = const [Color(0xFF1E293B), Color(0xFF475569)];
        iconData = Symbols.warning_rounded;
        accentColor = const Color(0xFFFBBF24);
    }

    return Container(
      width: 62,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MiniTrackWatermarkPainter(),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 16,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    SyncStatus status,
    AppLocalizations l10n,
    AppLanguage currentLang,
  ) {
    final isEnglish = currentLang == AppLanguage.en;

    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case SyncStatus.synced:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF1B8738);
        icon = Symbols.check_circle_rounded;
        label = isEnglish ? 'Synced' : l10n.syncStatusSynced;
        break;
      case SyncStatus.pending:
      case SyncStatus.syncing:
        bgColor = const Color(0xFFFEF3D6);
        textColor = const Color(0xFFB45309);
        icon = Symbols.sync_rounded;
        label = isEnglish ? 'Pending' : l10n.syncStatusPending;
        break;
      case SyncStatus.failed:
      case SyncStatus.conflict:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        icon = Symbols.error_rounded;
        label = isEnglish ? 'Failed' : l10n.syncStatusFailed;
        break;
      case SyncStatus.draft:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        icon = Symbols.edit_note_rounded;
        label = isEnglish ? 'Draft' : l10n.syncStatusDraft;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyHelplineCard(
    BuildContext context,
    AppLocalizations l10n,
    AppLanguage currentLang,
  ) {
    final title = _getEmergencyHelplineTitle(currentLang);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showEmergencyContactsBottomSheet(
              context,
              l10n,
              currentLang,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              child: Row(
                children: [
                  const Icon(
                    Symbols.call_rounded,
                    color: Color(0xFFB91C1C),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 18,
                    color: const Color(0xFFFECACA),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Symbols.open_in_new_rounded,
                    color: Color(0xFFB91C1C),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmergencyContactsBottomSheet(
    BuildContext context,
    AppLocalizations l10n,
    AppLanguage currentLang,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Symbols.call_rounded,
                      color: Color(0xFFB91C1C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Control Room',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'DHR Permanent-Way Emergency Lines',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildContactItem(
                title: 'DHR Division Control Office',
                subtitle: 'Kurseong / Katihar Operations Control',
                phone: '+91 354 234 4000',
                badgeText: 'Primary Control',
              ),
              const SizedBox(height: 10),
              _buildContactItem(
                title: 'Indian Railways Helpline',
                subtitle: 'All-India Railway Emergency & Support',
                phone: '139',
                badgeText: 'Toll-Free',
              ),
              const SizedBox(height: 10),
              _buildContactItem(
                title: 'National Emergency Service',
                subtitle: 'Police, Medical & Disaster Management',
                phone: '112',
                badgeText: 'Emergency',
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactItem({
    required String title,
    required String subtitle,
    required String phone,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF074E95),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(
                  Symbols.call_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEmergencyHelplineTitle(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hi:
        return 'आपातकालीन नियंत्रण कक्ष / हेल्पलाइन';
      case AppLanguage.bn:
        return 'জরুরি নিয়ন্ত্রণ কক্ষ / হেল্পলাইন';
      case AppLanguage.ne:
        return 'आपतकालीन नियन्त्रण कक्ष / हेल्पलाइन';
      case AppLanguage.en:
        return 'Emergency Control Room / Helpline';
    }
  }

  String _getReportTitle(
    BuildContext context,
    HazardReport report,
    AppLanguage currentLang,
  ) {
    if (currentLang == AppLanguage.en) {
      switch (report.confirmedHazardType) {
        case HazardType.vegetation:
          return 'Track Obstruction';
        case HazardType.trackDefect:
          return 'Track Damage';
        case HazardType.slip:
        case HazardType.rockfall:
          return 'Landslide / Rockfall';
        case HazardType.blockedDrain:
          return 'Blocked Drain';
        case HazardType.damagedWall:
          return 'Damaged Wall';
        case HazardType.other:
          return 'Alignment Hazard';
      }
    }
    return HazardIcon.getLocalizedLabel(context, report.confirmedHazardType);
  }

  String _formatLocation(HazardReport report) {
    final kmStr = report.kmMarker != null ? _formatKm(report.kmMarker!) : 'KM --';
    final station = report.nearestStationName ??
        DhrWaypoints.getSectionName(report.sectionId);
    return '$kmStr, $station';
  }

  String _formatKm(double km) {
    final intKm = km.floor();
    final remainder = ((km - intKm) * 10).round();
    if (remainder > 0) {
      return 'KM $intKm/$remainder';
    }
    return 'KM $intKm';
  }

  String _formatReportDate(DateTime dt, AppLocalizations l10n) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(local.year, local.month, local.day);
    final timeStr = DateFormat('hh:mm a').format(local);

    if (itemDay == today) {
      return '${l10n.today}, $timeStr';
    } else if (itemDay == today.subtract(const Duration(days: 1))) {
      return '${l10n.yesterday}, $timeStr';
    } else {
      return '${DateFormat('dd MMM').format(local)}, $timeStr';
    }
  }

  String _getRecentReportsTitle(AppLanguage lang, AppLocalizations l10n) {
    switch (lang) {
      case AppLanguage.hi:
        return 'हालिया रिपोर्टें';
      case AppLanguage.bn:
        return 'সাম্প্রতিক रिपोर्ट';
      case AppLanguage.ne:
        return 'हालका रिपोर्टहरू';
      case AppLanguage.en:
        return 'Recent Reports';
    }
  }

  String _getViewAllText(AppLanguage lang, AppLocalizations l10n) {
    switch (lang) {
      case AppLanguage.hi:
        return 'सभी देखें';
      case AppLanguage.bn:
        return 'সব দেখুন';
      case AppLanguage.ne:
        return 'सबै हेर्नुहोस्';
      case AppLanguage.en:
        return 'View All';
    }
  }

  List<HazardReport> _getSampleReports() {
    final now = DateTime.now();
    return [
      HazardReport(
        id: 'dhr-sample-001',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(now.year, now.month, now.day, 10, 24),
        updatedAt: DateTime(now.year, now.month, now.day, 10, 24),
        confirmedHazardType: HazardType.vegetation,
        confirmedSeverity: Severity.high,
        userNote: 'Fallen tree blocking the railway track near Kurseong.',
        kmMarker: 48.2,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Kurseong',
        syncStatus: SyncStatus.synced,
      ),
      HazardReport(
        id: 'dhr-sample-002',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(now.year, now.month, now.day, 8, 11),
        updatedAt: DateTime(now.year, now.month, now.day, 8, 11),
        confirmedHazardType: HazardType.trackDefect,
        confirmedSeverity: Severity.medium,
        userNote: 'Fishplate loosening and rail joint defect near Tung.',
        kmMarker: 47.8,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Tung',
        syncStatus: SyncStatus.pending,
      ),
      HazardReport(
        id: 'dhr-sample-003',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(now.year, now.month, now.day - 1, 17, 36),
        updatedAt: DateTime(now.year, now.month, now.day - 1, 17, 36),
        confirmedHazardType: HazardType.rockfall,
        confirmedSeverity: Severity.critical,
        userNote: 'Landslide and boulders covering the track alignment.',
        kmMarker: 49.4,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Sonada',
        syncStatus: SyncStatus.synced,
      ),
    ];
  }
}

class _RecentReportsHeaderIcon extends StatelessWidget {
  const _RecentReportsHeaderIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Symbols.article_rounded,
      color: Color(0xFF074E95),
      size: 22,
    );
  }
}

class _MiniTrackWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final railPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2.0;

    final sleeperPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2.5;

    // Two rails
    final leftRail = size.width * 0.28;
    final rightRail = size.width * 0.72;
    canvas.drawLine(
      Offset(leftRail, 0),
      Offset(leftRail, size.height),
      railPaint,
    );
    canvas.drawLine(
      Offset(rightRail, 0),
      Offset(rightRail, size.height),
      railPaint,
    );

    // Sleepers across
    for (double y = 8; y < size.height; y += 12) {
      canvas.drawLine(
        Offset(leftRail - 6, y),
        Offset(rightRail + 6, y),
        sleeperPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraWithSparksIcon extends StatelessWidget {
  const _CameraWithSparksIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(
            Symbols.photo_camera_rounded,
            size: 36,
            color: Colors.white,
          ),
          Positioned(
            top: 2,
            right: 2,
            child: CustomPaint(
              size: const Size(12, 12),
              painter: _SparksPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC107)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // 3 radiant rays
    canvas.drawLine(const Offset(3, 8), const Offset(1, 4), paint);
    canvas.drawLine(const Offset(6, 6), const Offset(9, 2), paint);
    canvas.drawLine(const Offset(8, 9), const Offset(12, 10), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagonalStripesPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double spacing;

  const _DiagonalStripesPainter({
    required this.color,
    this.strokeWidth = 3.5,
    this.spacing = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final total = size.width + size.height;
    for (double i = -size.height; i < total; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter oldDelegate) =>
      color != oldDelegate.color;
}
