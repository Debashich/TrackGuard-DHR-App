import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/inspection_status.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/language_selector_button.dart';
import '../../../shared/widgets/logout_confirmation.dart';
import '../../../shared/widgets/role_navigation_drawer.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(Supabase.instance.client),
);

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _tab = 0;
  late Future<List<HazardReport>> _reports;
  late Future<List<AppUser>> _profiles;
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _reports = _repo.fetchReports();
    _profiles = _repo.fetchProfiles();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_reports, _profiles]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      drawer: const RoleNavigationDrawer(currentRoute: '/admin/dashboard'),
      appBar: AppBar(
        leading: const LanguageSelectorButton(),
        centerTitle: true,
        title: const Text(
          'TrackGuard DHR',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
        actions: [
          IconButton(
            tooltip: l10n.navigationRefresh,
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () => _refresh().catchError((_) {}),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.navigationProfile,
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.signOut,
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () => showLogoutConfirmationDialog(context, ref),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
            title: Text(user?.fullName ?? l10n.roleAdmin),
            subtitle: Text(user?.assignedSection != null ? DhrWaypoints.getSectionName(user!.assignedSection!) : l10n.allDhrAlignment),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: () => context.push('/profile'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(l10n.adminOverviewTab),
                  icon: const Icon(Icons.dashboard_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text(l10n.adminReportsTab),
                  icon: const Icon(Icons.assignment_outlined),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text(l10n.adminUsersTab),
                  icon: const Icon(Icons.people_outline),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tab == 2 ? _usersView(l10n) : _reportsView(l10n, overview: _tab == 0),
          ),
        ],
      ),
    );
  }

  Widget _reportsView(
    AppLocalizations l10n, {
    required bool overview,
  }) => FutureBuilder<List<HazardReport>>(
    future: _reports,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _error(
          l10n.adminUpdateFailed('${snapshot.error}'),
          () => setState(_reload),
        );
      }
      final reports = snapshot.data ?? [];
      if (reports.isEmpty) {
        return Center(child: Text(l10n.adminNoRemoteReportsFound));
      }
      final counts = {
        for (final s in InspectionStatus.values)
          s: reports.where((r) => r.inspectionStatus == s).length,
      };
      final sections = <String, int>{};
      for (final r in reports) {
        sections.update(r.sectionId, (n) => n + 1, ifAbsent: () => 1);
      }
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (overview) ...[
              _SectionHeading(l10n.adminReportOverview),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _Metric(l10n.adminTotalReports, reports.length, Icons.assignment),
                  _Metric(
                    l10n.statusOpen,
                    counts[InspectionStatus.open] ?? 0,
                    Icons.fiber_new,
                    color: AppTheme.statusRed,
                  ),
                  _Metric(
                    l10n.statusAcknowledged,
                    counts[InspectionStatus.acknowledged] ?? 0,
                    Icons.check_circle_outline,
                    color: AppTheme.statusAmber,
                  ),
                  _Metric(
                    l10n.statusInspectionRequired,
                    counts[InspectionStatus.inspectionRequired] ?? 0,
                    Icons.build_circle_outlined,
                    color: AppTheme.statusOrange,
                  ),
                  _Metric(
                    l10n.statusResolved,
                    counts[InspectionStatus.resolved] ?? 0,
                    Icons.task_alt,
                    color: AppTheme.statusGreen,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionHeading(l10n.adminSectionSummary),
              ...sections.entries.map(
                (e) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.alt_route,
                      color: AppTheme.primaryAmber,
                    ),
                    title: Text(_sectionName(e.key)),
                    trailing: Text('${e.value}'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionHeading(l10n.adminLatestReports),
            ],
            ...reports.map(
              (report) => Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.primaryAmber,
                  ),
                  title: Text(
                    '${report.confirmedHazardType.name} • ${report.confirmedSeverity.name}',
                  ),
                  subtitle: Text(
                    '${_sectionName(report.sectionId)} • ${report.createdAt.toLocal()}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AdminReportDetailScreen(reportId: report.id),
                      ),
                    );
                    if (mounted) setState(_reload);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _usersView(AppLocalizations l10n) => FutureBuilder<List<AppUser>>(
    future: _profiles,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _error(
          l10n.adminUpdateFailed('${snapshot.error}'),
          () => setState(_reload),
        );
      }
      final users = snapshot.data ?? [];
      if (users.isEmpty) return Center(child: Text(l10n.adminNoProfilesFound));
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) => _UserCard(
            user: users[index],
            repo: _repo,
            onChanged: () => setState(_reload),
          ),
        ),
      );
    },
  );
}

class _UserCard extends StatefulWidget {
  const _UserCard({
    required this.user,
    required this.repo,
    required this.onChanged,
  });
  final AppUser user;
  final AdminRepository repo;
  final VoidCallback onChanged;
  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  late bool active = widget.user.isActive;
  late UserRole role = widget.user.role;
  late final TextEditingController section = TextEditingController(
    text: widget.user.assignedSection ?? '',
  );
  bool saving = false;
  @override
  void dispose() {
    section.dispose();
    super.dispose();
  }

  Future<void> _save({
    bool? nextActive,
    UserRole? nextRole,
    String? nextSection,
  }) async {
    setState(() => saving = true);
    try {
      final newActive = nextActive ?? active;
      final newRole = nextRole ?? role;
      final newSection = nextSection ?? section.text;
      await widget.repo.updateProfile(
        id: widget.user.id,
        isActive: newActive,
        role: newRole,
        assignedSection: newSection.trim().isEmpty ? null : newSection.trim(),
      );
      if (!mounted) return;
      setState(() {
        active = newActive;
        role = newRole;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person_outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.fullName ?? 'Unnamed user',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      widget.user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: saving ? null : (v) => _save(nextActive: v),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Role '),
              DropdownButton<UserRole>(
                value: role,
                items: UserRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: saving
                    ? null
                    : (r) {
                        if (r != null) _save(nextRole: r);
                      },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: section.text.isEmpty ? null : section.text,
                  decoration: const InputDecoration(
                    labelText: 'Assigned section',
                    isDense: true,
                  ),
                  items: DhrWaypoints.sections
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            s.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (v) {
                          if (v != null) {
                            section.text = v;
                            _save(nextSection: v);
                          }
                        },
                ),
              ),
            ],
          ),
          Text(
            active ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              color: active ? AppTheme.statusGreen : AppTheme.statusRed,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

class AdminReportDetailScreen extends ConsumerStatefulWidget {
  const AdminReportDetailScreen({super.key, required this.reportId});
  final String reportId;
  @override
  ConsumerState<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState
    extends ConsumerState<AdminReportDetailScreen> {
  late Future<HazardReport?> reportFuture;
  late Future<List<Map<String, dynamic>>> historyFuture;
  late Future<String?> mediaUrlFuture;
  InspectionStatus? selected;
  bool saving = false;
  AdminRepository get repo => ref.read(adminRepositoryProvider);
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    reportFuture = repo.fetchReport(widget.reportId);
    historyFuture = repo.fetchHistory(widget.reportId);
    mediaUrlFuture = repo.fetchReportMediaUrl(widget.reportId);
  }

  Future<void> _save(HazardReport report) async {
    if (selected == null || selected == report.inspectionStatus) return;
    setState(() => saving = true);
    try {
      await repo.updateStatus(report.id, selected!);
      if (!mounted) return;
      setState(() {
        _reload();
        selected = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated. Check audit history below.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Status update failed: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin report detail')),
    body: FutureBuilder<HazardReport?>(
      future: reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _error(
            'Could not load report: ${snapshot.error}',
            () => setState(_reload),
          );
        }
        final r = snapshot.data;
        if (r == null) {
          return const Center(
            child: Text('Report not found or access denied.'),
          );
        }
        final current = selected ?? r.inspectionStatus;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImageSection(r),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.confirmedHazardType.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Severity: ${r.confirmedSeverity.name}'),
                    Text('Section: ${_sectionName(r.sectionId)}'),
                    Text('Station: ${r.nearestStationName ?? 'Not specified'}'),
                    Text(
                      'Km marker: ${r.kmMarker?.toStringAsFixed(1) ?? 'Not specified'}',
                    ),
                    Text('Created: ${r.createdAt.toLocal()}'),
                    Text(
                      'Report ID: ${r.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (r.userNote.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text('Gangman note'),
                      Text(r.userNote),
                    ],
                    if (r.aiNote?.isNotEmpty == true) ...[
                      const Divider(height: 24),
                      const Text('AI suggestion'),
                      Text(r.aiNote!),
                      Text(
                        'Provider: ${r.aiProvider.name} • Model: ${r.aiModel ?? 'n/a'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    if (r.latitude != null && r.longitude != null)
                      Text('GPS: ${r.latitude}, ${r.longitude}'),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeading('UPDATE STATUS'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<InspectionStatus>(
                      isExpanded: true,
                      initialValue: current,
                      decoration: const InputDecoration(
                        labelText: 'Inspection status',
                      ),
                      items: InspectionStatus.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(_statusLabel(s)),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (s) => setState(() => selected = s),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: saving || current == r.inspectionStatus
                          ? null
                          : () => _save(r),
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(saving ? 'Saving…' : 'Save status'),
                    ),
                  ],
                ),
              ),
            ),
            const _SectionHeading('AUDIT HISTORY'),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: historyFuture,
              builder: (context, history) {
                if (history.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (history.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Could not load history: ${history.error}'),
                    ),
                  );
                }
                final rows = history.data ?? [];
                if (rows.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No status changes recorded yet.'),
                    ),
                  );
                }
                return Column(
                  children: rows
                      .map(
                        (h) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.history,
                              color: AppTheme.primaryAmber,
                            ),
                            title: Text(
                              '${h['from_status'] ?? 'Initial'} → ${h['to_status'] ?? 'Unknown'}',
                            ),
                            subtitle: Text(
                              'Changed by ${h['changed_by'] ?? 'unknown'}\n${h['created_at'] ?? ''}${h['comment'] == null ? '' : '\n${h['comment']}'}',
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    ),
  );

  Widget _buildImageSection(HazardReport r) {
    return FutureBuilder<String?>(
      future: mediaUrlFuture,
      builder: (context, snapshot) {
        final remoteUrl = snapshot.data;
        final localPath = r.originalPhotoPath ?? r.thumbnailPhotoPath;
        final hasLocal = localPath != null && File(localPath).existsSync();

        if (snapshot.connectionState == ConnectionState.waiting && !hasLocal) {
          return const Card(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading inspection photo...'),
                  ],
                ),
              ),
            ),
          );
        }

        final hasImage =
            (remoteUrl != null && remoteUrl.isNotEmpty) || hasLocal;
        if (!hasImage) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 44,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No inspection photo available for this report',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        Widget imageWidget;
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          imageWidget = Image.network(
            remoteUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 220,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 220,
                color: Colors.black12,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => hasLocal
                ? Image.file(
                    File(localPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                  )
                : Container(
                    height: 180,
                    color: Colors.black12,
                    child: const Center(
                      child: Text('Failed to load image from storage'),
                    ),
                  ),
          );
        } else if (localPath != null) {
          imageWidget = Image.file(
            File(localPath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 220,
          );
        } else {
          imageWidget = const SizedBox.shrink();
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _openFullScreenImage(
              remoteUrl,
              hasLocal ? localPath : null,
            ),
            child: Stack(
              children: [
                imageWidget,
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Tap to enlarge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INSPECTION PHOTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullScreenImage(String? remoteUrl, String? localPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Hazard Photo',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: remoteUrl != null && remoteUrl.isNotEmpty
                  ? Image.network(
                      remoteUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => localPath != null
                          ? Image.file(File(localPath), fit: BoxFit.contain)
                          : const Center(
                              child: Text(
                                'Failed to load full image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                    )
                  : (localPath != null
                      ? Image.file(File(localPath), fit: BoxFit.contain)
                      : const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
    this.label,
    this.value,
    this.icon, {
    this.color = AppTheme.primaryAmber,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppTheme.primaryAmber,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );
}

Widget _error(String message, VoidCallback retry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off, size: 40),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  ),
);

String _statusLabel(InspectionStatus s) {
  switch (s) {
    case InspectionStatus.open:
      return 'Open';
    case InspectionStatus.acknowledged:
      return 'Acknowledged';
    case InspectionStatus.inspectionRequired:
      return 'Inspection required';
    case InspectionStatus.resolved:
      return 'Resolved';
  }
}

String _sectionName(String id) {
  switch (id) {
    case 'kurseong-ghum':
      return 'Kurseong → Ghum';
    case 'ghum-darjeeling':
      return 'Ghum → Darjeeling';
    default:
      return id;
  }
}
