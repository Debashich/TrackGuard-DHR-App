import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/inspection_status.dart';
import '../../../shared/models/user_role.dart';
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
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      drawer: const RoleNavigationDrawer(currentRoute: '/admin/dashboard'),
      appBar: AppBar(
        title: const Text('TrackGuard Admin'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh().catchError((_) {}),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => showLogoutConfirmationDialog(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
            title: Text(user?.fullName ?? 'Supervisor'),
            subtitle: Text(user?.assignedSection ?? 'All assigned sections'),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () => context.push('/profile'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Overview'),
                  icon: Icon(Icons.dashboard_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Reports'),
                  icon: Icon(Icons.assignment_outlined),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('Users'),
                  icon: Icon(Icons.people_outline),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tab == 2 ? _usersView() : _reportsView(overview: _tab == 0),
          ),
        ],
      ),
    );
  }

  Widget _reportsView({
    required bool overview,
  }) => FutureBuilder<List<HazardReport>>(
    future: _reports,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _error(
          'Could not load reports: ${snapshot.error}',
          () => setState(_reload),
        );
      }
      final reports = snapshot.data ?? [];
      if (reports.isEmpty) {
        return const Center(child: Text('No remote reports found.'));
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
              const _SectionHeading('REPORT OVERVIEW'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _Metric('Total reports', reports.length, Icons.assignment),
                  _Metric(
                    'Open',
                    counts[InspectionStatus.open] ?? 0,
                    Icons.fiber_new,
                    color: AppTheme.statusRed,
                  ),
                  _Metric(
                    'Acknowledged',
                    counts[InspectionStatus.acknowledged] ?? 0,
                    Icons.check_circle_outline,
                    color: AppTheme.statusAmber,
                  ),
                  _Metric(
                    'Inspection required',
                    counts[InspectionStatus.inspectionRequired] ?? 0,
                    Icons.build_circle_outlined,
                    color: AppTheme.statusOrange,
                  ),
                  _Metric(
                    'Resolved',
                    counts[InspectionStatus.resolved] ?? 0,
                    Icons.task_alt,
                    color: AppTheme.statusGreen,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _SectionHeading('SECTION SUMMARY'),
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
              const _SectionHeading('LATEST REPORTS'),
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

  Widget _usersView() => FutureBuilder<List<AppUser>>(
    future: _profiles,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _error(
          'Could not load profiles: ${snapshot.error}',
          () => setState(_reload),
        );
      }
      final users = snapshot.data ?? [];
      if (users.isEmpty) return const Center(child: Text('No profiles found.'));
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
                  initialValue: section.text.isEmpty ? null : section.text,
                  decoration: const InputDecoration(labelText: 'Assigned section', isDense: true),
                  items: DhrWaypoints.sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: saving ? null : (v) { if (v != null) { section.text = v; _save(nextSection: v); } },
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
