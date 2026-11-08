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
import '../../../shared/widgets/role_navigation_drawer.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(Supabase.instance.client),
);

class _C {
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const brand = Color(0xFF074E95);
  static const brandSoft = Color(0xFFE8F1FA);
  static const border = Color(0xFFE2E8F0);
  static const canvas = Color(0xFFF3F5F9);
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;
  InspectionStatus? _filter;
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

  Future<void> _openReport(HazardReport report) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminReportDetailScreen(reportId: report.id),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _C.canvas,
      // Hamburger now lives on the left, so the drawer slides in from the left.
      drawer: const RoleNavigationDrawer(currentRoute: '/admin/dashboard'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: _C.ink,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'TrackGuard DHR',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _C.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.navigationProfile,
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          const LanguageSelectorButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [_overviewTab(l10n), _reportsTab(l10n), _usersTab(l10n)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _C.brandSoft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }

  Widget _reportsFuture(
    AppLocalizations l10n,
    Widget Function(List<HazardReport> reports) builder,
  ) => FutureBuilder<List<HazardReport>>(
    future: _reports,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
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
        return _Empty(
          icon: Icons.inbox_outlined,
          text: l10n.adminNoRemoteReportsFound,
        );
      }
      return RefreshIndicator(onRefresh: _refresh, child: builder(reports));
    },
  );

  // -- Overview --------------------------------------------------------------

  String _statusText(AppLocalizations l10n, InspectionStatus s) {
    switch (s) {
      case InspectionStatus.open:
        return l10n.statusOpen;
      case InspectionStatus.acknowledged:
        return l10n.statusAcknowledged;
      case InspectionStatus.inspectionRequired:
        return l10n.statusInspectionRequired;
      case InspectionStatus.resolved:
        return l10n.statusResolved;
    }
  }

  Widget _overviewTab(AppLocalizations l10n) => _reportsFuture(l10n, (reports) {
    final counts = {
      for (final s in InspectionStatus.values)
        s: reports.where((r) => r.inspectionStatus == s).length,
    };
    final sections = <String, int>{};
    for (final r in reports) {
      sections.update(r.sectionId, (n) => n + 1, ifAbsent: () => 1);
    }
    final open = counts[InspectionStatus.open] ?? 0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _HeroCard(
          title: open == 0
              ? 'All clear'
              : open == 1
              ? '1 report needs a look'
              : '$open reports need a look',
          subtitle: open == 0
              ? 'Nothing waiting. ${reports.length} reported so far.'
              : '${reports.length} reported so far across the line.',
          onTap: () => setState(() {
            _filter = open == 0 ? null : InspectionStatus.open;
            _tab = 1;
          }),
        ),
        const SizedBox(height: 16),
        _Panel(
          icon: Icons.insights_outlined,
          title: l10n.adminReportOverview,
          rows: [
            _StatusOverview(
              counts: counts,
              labelOf: (s) => _statusText(l10n, s),
              onSelect: (s) => setState(() {
                _filter = s;
                _tab = 1;
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          icon: Icons.alt_route,
          title: l10n.adminSectionSummary,
          rows: [
            for (final e in sections.entries)
              _SectionRow(name: _sectionName(e.key), count: e.value),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          icon: Icons.article_outlined,
          title: l10n.adminLatestReports,
          trailing: TextButton.icon(
            onPressed: () => setState(() {
              _filter = null;
              _tab = 1;
            }),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text(
              'View All',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          rows: [
            for (final r in reports.take(5))
              _ReportRow(report: r, onTap: () => _openReport(r)),
          ],
        ),
      ],
    );
  });

  // -- Reports ---------------------------------------------------------------

  Widget _reportsTab(AppLocalizations l10n) => _reportsFuture(l10n, (reports) {
    final shown = _filter == null
        ? reports
        : reports.where((r) => r.inspectionStatus == _filter).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All (${reports.length})',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final s in InspectionStatus.values)
                _FilterChip(
                  label: _statusLabel(s),
                  selected: _filter == s,
                  onTap: () => setState(() => _filter = s),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: _Empty(
              icon: Icons.filter_alt_off_outlined,
              text: 'No reports with this status.',
            ),
          )
        else
          _Panel(
            rows: [
              for (final r in shown)
                _ReportRow(report: r, onTap: () => _openReport(r)),
            ],
          ),
      ],
    );
  });

  // -- Users -----------------------------------------------------------------

  Widget _usersTab(AppLocalizations l10n) => FutureBuilder<List<AppUser>>(
    future: _profiles,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _error(
          'Could not load users: ${snapshot.error}',
          () => setState(_reload),
        );
      }
      final users = snapshot.data ?? [];
      if (users.isEmpty) {
        return _Empty(
          icon: Icons.people_outline,
          text: l10n.adminNoProfilesFound,
        );
      }
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: users.length,
          itemBuilder: (context, index) => _UserCard(
            key: ValueKey(users[index].id),
            user: users[index],
            repo: _repo,
            onChanged: () => setState(_reload),
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

class _UserCard extends StatefulWidget {
  const _UserCard({
    super.key,
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
  late String? sectionId = widget.user.assignedSection;
  bool saving = false;

  Future<void> _save({
    required bool nextActive,
    required UserRole nextRole,
    required String? nextSection,
  }) async {
    setState(() => saving = true);
    try {
      await widget.repo.updateProfile(
        id: widget.user.id,
        isActive: nextActive,
        role: nextRole,
        assignedSection: nextSection,
      );
      if (!mounted) return;
      setState(() {
        active = nextActive;
        role = nextRole;
        sectionId = nextSection;
      });
      _toast('Profile updated');
      widget.onChanged();
    } catch (e) {
      _toast('Update failed: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.fullName;
    final known = DhrWaypoints.sections.any((s) => s.id == sectionId);
    return _DashboardCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _C.brandSoft,
                  foregroundColor: _C.brand,
                  child: Text(
                    (name != null && name.isNotEmpty ? name[0] : '?')
                        .toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? 'Unnamed user',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _C.ink,
                        ),
                      ),
                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: _C.muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(
                      value: active,
                      onChanged: saving
                          ? null
                          : (v) => _save(
                              nextActive: v,
                              nextRole: role,
                              nextSection: sectionId,
                            ),
                    ),
                    Text(
                      active ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppTheme.statusGreen
                            : AppTheme.statusRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Field<UserRole>(
              label: 'Role',
              value: role,
              items: UserRole.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(_humanize(r.name)),
                    ),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (r) {
                      if (r != null && r != role) {
                        _save(
                          nextActive: active,
                          nextRole: r,
                          nextSection: sectionId,
                        );
                      }
                    },
            ),
            const SizedBox(height: 12),
            _Field<String?>(
              label: 'Assigned section',
              value: sectionId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All sections'),
                ),
                ...DhrWaypoints.sections.map(
                  (s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (sectionId != null && !known)
                  DropdownMenuItem<String?>(
                    value: sectionId,
                    child: Text(sectionId!),
                  ),
              ],
              onChanged: saving
                  ? null
                  : (v) {
                      if (v != sectionId) {
                        _save(
                          nextActive: active,
                          nextRole: role,
                          nextSection: v,
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _Field<T> extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        isDense: true,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Report detail
// ---------------------------------------------------------------------------

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
      _toast('Status updated');
    } catch (e) {
      _toast('Status update failed: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.canvas,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      foregroundColor: _C.ink,
      title: const Text(
        'Report details',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    body: FutureBuilder<HazardReport?>(
      future: reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
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
          return const _Empty(
            icon: Icons.lock_outline,
            text: 'Report not found or access denied.',
          );
        }
        final current = selected ?? r.inspectionStatus;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _imageSection(r),
            _DashboardCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _humanize(r.confirmedHazardType.name),
                            style: const TextStyle(
                              color: _C.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusPill(status: r.inspectionStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow('Severity', _humanize(r.confirmedSeverity.name)),
                    _InfoRow('Section', _sectionName(r.sectionId)),
                    _InfoRow(
                      'Station',
                      r.nearestStationName ?? 'Not specified',
                    ),
                    _InfoRow(
                      'Km marker',
                      r.kmMarker == null
                          ? 'Not specified'
                          : _trimKm(r.kmMarker!),
                    ),
                    _InfoRow('Created', _formatDate(r.createdAt)),
                    if (r.latitude != null && r.longitude != null)
                      _InfoRow('GPS', '${r.latitude}, ${r.longitude}'),
                    _InfoRow('Report ID', r.id, selectable: true),
                    if (r.userNote.isNotEmpty)
                      _NoteBlock(title: 'Gangman note', text: r.userNote),
                    if (r.aiNote?.isNotEmpty == true)
                      _NoteBlock(
                        title: 'AI suggestion',
                        text: r.aiNote!,
                        footer:
                            '${r.aiProvider.name} • ${r.aiModel ?? 'model n/a'}',
                      ),
                  ],
                ),
              ),
            ),
            _DashboardCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Update status',
                      style: TextStyle(
                        color: _C.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Field<InspectionStatus>(
                      label: 'Inspection status',
                      value: current,
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
                    FilledButton.icon(
                      onPressed: saving || current == r.inspectionStatus
                          ? null
                          : () => _save(r),
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Saving…' : 'Save status'),
                    ),
                  ],
                ),
              ),
            ),
            _history(),
          ],
        );
      },
    ),
  );

  Widget _history() => FutureBuilder<List<Map<String, dynamic>>>(
    future: historyFuture,
    builder: (context, history) {
      if (history.connectionState == ConnectionState.waiting &&
          !history.hasData) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final rows = history.data ?? [];
      final Widget body;
      if (history.hasError) {
        body = Text('Could not load history: ${history.error}');
      } else if (rows.isEmpty) {
        body = const Text(
          'No status changes recorded yet.',
          style: TextStyle(color: _C.muted),
        );
      } else {
        body = Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 24, color: _C.border),
              _historyRow(rows[i]),
            ],
          ],
        );
      }
      return _DashboardCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Audit history',
                style: TextStyle(
                  color: _C.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              body,
            ],
          ),
        ),
      );
    },
  );

  Widget _historyRow(Map<String, dynamic> h) {
    final from = h['from_status'] == null
        ? 'Initial'
        : _humanize('${h['from_status']}');
    final to = h['to_status'] == null
        ? 'Unknown'
        : _humanize('${h['to_status']}');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.history, color: _C.brand),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$from → $to',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'By ${h['changed_by'] ?? 'unknown'} • ${_formatRaw(h['created_at'])}',
                style: const TextStyle(fontSize: 12, color: _C.muted),
              ),
              if (h['comment'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${h['comment']}'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageSection(HazardReport r) => FutureBuilder<String?>(
    future: mediaUrlFuture,
    builder: (context, snapshot) {
      final remoteUrl = snapshot.data;
      final rawLocal = r.originalPhotoPath ?? r.thumbnailPhotoPath;
      final localPath = (rawLocal != null && File(rawLocal).existsSync())
          ? rawLocal
          : null;
      final hasRemote = remoteUrl != null && remoteUrl.isNotEmpty;

      if (snapshot.connectionState == ConnectionState.waiting &&
          localPath == null) {
        return const _DashboardCard(
          child: SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (!hasRemote && localPath == null) {
        return const _DashboardCard(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: _Empty(
              icon: Icons.image_not_supported_outlined,
              text: 'No inspection photo for this report',
            ),
          ),
        );
      }

      return _DashboardCard(
        onTap: () => _openFullScreenImage(remoteUrl, localPath),
        child: Stack(
          children: [
            _photo(
              remoteUrl: remoteUrl,
              localPath: localPath,
              fit: BoxFit.cover,
              height: 220,
            ),
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
          ],
        ),
      );
    },
  );

  void _openFullScreenImage(String? remoteUrl, String? localPath) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Hazard photo',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: _photo(
                remoteUrl: remoteUrl,
                localPath: localPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Remote image with a local-file fallback, then a plain placeholder.
Widget _photo({
  String? remoteUrl,
  String? localPath,
  required BoxFit fit,
  double? height,
}) {
  Widget fallback() => localPath != null
      ? Image.file(
          File(localPath),
          fit: fit,
          width: double.infinity,
          height: height,
        )
      : Container(
          height: height ?? 180,
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Text('Failed to load image'),
        );

  if (remoteUrl == null || remoteUrl.isEmpty) return fallback();
  return Image.network(
    remoteUrl,
    fit: fit,
    width: double.infinity,
    height: height,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return Container(
        height: height ?? 220,
        color: Colors.black12,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
        ),
      );
    },
    errorBuilder: (_, _, _) => fallback(),
  );
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

/// Blue call-to-action card, same shape as the gangman home screen.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _C.brand,
    borderRadius: BorderRadius.circular(28),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
        child: Row(
          children: [
            const Icon(
              Icons.assignment_late_outlined,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 52, color: Colors.white24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: _C.brand),
            ),
          ],
        ),
      ),
    ),
  );
}

/// White rounded list card with an optional header. Rows get dividers.
class _Panel extends StatelessWidget {
  const _Panel({this.icon, this.title, this.trailing, required this.rows});
  final IconData? icon;
  final String? title;
  final Widget? trailing;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    radius: 24,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: _C.brand, size: 26),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        color: _C.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _C.border),
            rows[i],
          ],
        ],
      ),
    ),
  );
}

/// Proportion bar plus a 2-column grid of tappable status tiles.
class _StatusOverview extends StatelessWidget {
  const _StatusOverview({
    required this.counts,
    required this.labelOf,
    required this.onSelect,
  });
  final Map<InspectionStatus, int> counts;
  final String Function(InspectionStatus) labelOf;
  final ValueChanged<InspectionStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    final all = InspectionStatus.values;
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    Widget tile(InspectionStatus s) {
      final color = _statusColor(s);
      return Material(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelect(s),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(s), color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labelOf(s),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: _C.muted),
                      ),
                      Text(
                        '${counts[s] ?? 0}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _C.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    for (final s in all)
                      if ((counts[s] ?? 0) > 0)
                        Expanded(
                          flex: counts[s]!,
                          child: ColoredBox(color: _statusColor(s)),
                        ),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < all.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(child: tile(all[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < all.length
                        ? tile(all[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.name, required this.count});
  final String name;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _C.brandSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.alt_route, color: _C.brand, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _C.ink,
            ),
          ),
        ),
        Text(
          '$count ${count == 1 ? 'report' : 'reports'}',
          style: const TextStyle(fontSize: 13, color: _C.muted),
        ),
      ],
    ),
  );
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onTap});
  final HazardReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rawThumb = report.thumbnailPhotoPath ?? report.originalPhotoPath;
    final thumb = (rawThumb != null && File(rawThumb).existsSync())
        ? rawThumb
        : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68,
                height: 68,
                child: thumb != null
                    ? Image.file(File(thumb), fit: BoxFit.cover, cacheWidth: 200)
                    : const ColoredBox(
                        color: _C.brandSoft,
                        child: Icon(
                          Icons.image_outlined,
                          color: _C.brand,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _humanize(report.confirmedHazardType.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _C.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _MetaLine(Icons.location_on_outlined, _locationLabel(report)),
                  const SizedBox(height: 2),
                  _MetaLine(
                    Icons.calendar_today_outlined,
                    _formatDate(report.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(status: report.inspectionStatus, compact: true),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: _C.muted),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: _C.muted),
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.selectable = false});
  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: _C.ink,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: _C.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: style.copyWith(fontSize: 12))
                : Text(value, style: style),
          ),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.title, required this.text, this.footer});
  final String title;
  final String text;
  final String? footer;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.canvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _C.brand,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(text),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Text(footer!, style: const TextStyle(fontSize: 12, color: _C.muted)),
          ],
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _C.brand,
      backgroundColor: Colors.white,
      side: const BorderSide(color: _C.border),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : _C.ink,
      ),
    ),
  );
}

/// White rounded card. Material (not a decorated Container) so ripples show.
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, this.onTap, this.radius = 20});
  final Widget child;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: _C.border),
      ),
      child: onTap == null ? child : InkWell(onTap: onTap, child: child),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, this.compact = false});
  final InspectionStatus status;

  /// In list rows: drop the icon so long labels like "Inspection required"
  /// don't crush the location text on narrow phones.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(_statusIcon(status), size: 16, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            compact ? _statusShortLabel(status) : _statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: _C.muted),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _C.muted, fontSize: 14),
          ),
        ],
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
        const Icon(Icons.cloud_off, size: 40, color: _C.muted),
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _statusColor(InspectionStatus s) {
  switch (s) {
    case InspectionStatus.open:
      return AppTheme.statusRed;
    case InspectionStatus.acknowledged:
      return AppTheme.statusAmber;
    case InspectionStatus.inspectionRequired:
      return AppTheme.statusOrange;
    case InspectionStatus.resolved:
      return AppTheme.statusGreen;
  }
}

IconData _statusIcon(InspectionStatus s) => switch (s) {
  InspectionStatus.open => Icons.error_outline,
  InspectionStatus.acknowledged => Icons.visibility_outlined,
  InspectionStatus.inspectionRequired => Icons.build_circle_outlined,
  InspectionStatus.resolved => Icons.check_circle_outline,
};

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

/// Shorter labels for the compact pill in list rows.
String _statusShortLabel(InspectionStatus s) {
  switch (s) {
    case InspectionStatus.open:
      return 'Open';
    case InspectionStatus.acknowledged:
      return 'Seen';
    case InspectionStatus.inspectionRequired:
      return 'Inspect';
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

String _trimKm(num km) =>
    km == km.roundToDouble() ? '${km.toInt()}' : km.toStringAsFixed(1);

/// "KM 51, Kurseong", falling back to the section name.
String _locationLabel(HazardReport r) {
  final station = r.nearestStationName;
  final parts = [
    if (r.kmMarker != null) 'KM ${_trimKm(r.kmMarker!)}',
    if (station != null && station.isNotEmpty) station,
  ];
  return parts.isEmpty ? _sectionName(r.sectionId) : parts.join(', ');
}

/// `inspectionRequired` / `inspection_required` -> `Inspection required`.
String _humanize(String raw) {
  final spaced = raw
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
      )
      .replaceAll('_', ' ')
      .trim()
      .toLowerCase();
  if (spaced.isEmpty) return raw;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final d = date.toLocal();
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${months[d.month - 1]}, $hour:$minute $period';
}

String _formatRaw(Object? value) {
  if (value == null) return '';
  final parsed = DateTime.tryParse('$value');
  return parsed == null ? '$value' : _formatDate(parsed);
}