import 'dart:io';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/severity.dart';
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
  final TextEditingController _userSearchController = TextEditingController();
  String _userSearchQuery = '';
  int _tab = 0;
  InspectionStatus? _filter;
  late Future<List<HazardReport>> _reports;
  late Future<List<AppUser>> _profiles;
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  void initState() {
    super.initState();
    debugPrint('[ADMIN] initState');
    _reload();
  }

  @override
  void dispose() {
    debugPrint('[ADMIN] dispose');
    _userSearchController.dispose();
    super.dispose();
  }

  void _reload() {
    debugPrint('[ADMIN] _reload called');
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
        builder: (_) => AdminReportDetailScreen(
          reportId: report.id,
          initialReport: report,
        ),
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
          icon: const Icon(Symbols.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'TrackGuard DHR',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _C.ink,
            letterSpacing: -0.2,
          ),
        ),
        actions: const [
          LanguageSelectorButton(),
          SizedBox(width: 4),
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
            icon: Icon(Symbols.dashboard_rounded),
            selectedIcon: Icon(Symbols.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Symbols.assignment_rounded),
            selectedIcon: Icon(Symbols.assignment_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Symbols.group_rounded),
            selectedIcon: Icon(Symbols.group_rounded),
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
          icon: Symbols.inbox_rounded,
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
    // Sort reports by date descending (latest first)
    final sortedReports = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final counts = {
      for (final s in InspectionStatus.values)
        s: sortedReports.where((r) => r.inspectionStatus == s).length,
    };
    final sections = <String, int>{
      'kurseong-ghum': 0,
      'ghum-darjeeling': 0,
    };
    for (final r in sortedReports) {
      sections.update(r.sectionId, (n) => n + 1, ifAbsent: () => 1);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Panel(
          icon: Symbols.insights_rounded,
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
          icon: Symbols.alt_route_rounded,
          title: l10n.adminSectionSummary,
          rows: [
            for (final e in sections.entries)
              _SectionRow(name: _sectionName(e.key), count: e.value),
          ],
        ),
        const SizedBox(height: 16),
        _RecentReportsCard(
          reports: sortedReports.take(5).toList(),
          onTapReport: _openReport,
          onViewAll: () => setState(() {
            _filter = null;
            _tab = 1;
          }),
        ),
      ],
    );
  });

  // -- Reports ---------------------------------------------------------------

  Widget _reportsTab(AppLocalizations l10n) => _reportsFuture(l10n, (reports) {
    // Sort reports by date descending (latest first)
    final sortedReports = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final shown = _filter == null
        ? sortedReports
        : sortedReports.where((r) => r.inspectionStatus == _filter).toList();
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
              icon: Symbols.filter_alt_off_rounded,
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

  Widget _usersTab(AppLocalizations l10n) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => FocusScope.of(context).unfocus(),
    child: Column(
      children: [
        // Top User Search Bar (Mockup Design)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _userSearchController,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: (val) {
                setState(() {
                  _userSearchQuery = val;
                });
              },
            cursorColor: const Color(0xFF074E95),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              prefixIcon: const Icon(
                Symbols.search_rounded,
                color: Color(0xFF64748B),
                size: 22,
              ),
              hintText: 'Search users by name or email',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
              ),
              suffixIcon: _userSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      onPressed: () {
                        _userSearchController.clear();
                        setState(() {
                          _userSearchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),

      // Users List or Empty / Loading State
      Expanded(
        child: FutureBuilder<List<AppUser>>(
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
            final allUsers = snapshot.data ?? [];
            if (allUsers.isEmpty) {
              return _Empty(
                icon: Symbols.group_rounded,
                text: l10n.adminNoProfilesFound,
              );
            }

            final query = _userSearchQuery.trim().toLowerCase();
            final users = query.isEmpty
                ? allUsers
                : allUsers.where((u) {
                    final name = (u.fullName ?? '').toLowerCase();
                    final email = u.email.toLowerCase();
                    return name.contains(query) || email.contains(query);
                  }).toList();

            if (users.isEmpty && query.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.search_off_rounded,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No users matching "$_userSearchQuery"',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
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
        ),
      ),
    ],
  ),
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
    final initial = (name != null && name.trim().isNotEmpty
            ? name.trim()[0]
            : '?')
        .toUpperCase();
    final known = DhrWaypoints.sections.any((s) => s.id == sectionId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Avatar + Name & Email + Switch & Active label
          Row(
            children: [
              // Circular Avatar (Light blue circle with bold blue initial)
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF3FC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF074E95),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Unnamed user',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Switch + Status Label underneath
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: active,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF074E95),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      trackOutlineColor:
                          WidgetStateProperty.all(Colors.transparent),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: saving
                          ? null
                          : (v) => _save(
                              nextActive: v,
                              nextRole: role,
                              nextSection: sectionId,
                            ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    active ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Second Row: Role & Assigned Section Side-by-Side (Mockup Design)
          Row(
            children: [
              // Left: Role Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UserRole>(
                          value: role,
                          isExpanded: true,
                          icon: const Icon(
                            Symbols.arrow_drop_down_rounded,
                            color: Color(0xFF64748B),
                            size: 22,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: UserRole.admin,
                              child: Row(
                                children: const [
                                  Icon(
                                    Symbols.shield_person_rounded,
                                    size: 18,
                                    color: Color(0xFF074E95),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: UserRole.gangman,
                              child: Row(
                                children: const [
                                  Icon(
                                    Symbols.engineering_rounded,
                                    size: 18,
                                    color: Color(0xFF074E95),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Gangman',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Right: Assigned Section Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned Section',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: sectionId,
                          isExpanded: true,
                          icon: const Icon(
                            Symbols.arrow_drop_down_rounded,
                            color: Color(0xFF64748B),
                            size: 22,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(
                                    Symbols.alt_route_rounded,
                                    size: 18,
                                    color: Color(0xFF074E95),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'All sections',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...DhrWaypoints.sections.map(
                              (s) => DropdownMenuItem<String?>(
                                value: s.id,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Symbols.alt_route_rounded,
                                      size: 18,
                                      color: Color(0xFF074E95),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (sectionId != null && !known)
                              DropdownMenuItem<String?>(
                                value: sectionId,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Symbols.alt_route_rounded,
                                      size: 18,
                                      color: Color(0xFF074E95),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sectionId!,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Report detail
// ---------------------------------------------------------------------------

class AdminReportDetailScreen extends ConsumerStatefulWidget {
  const AdminReportDetailScreen({
    super.key,
    required this.reportId,
    this.initialReport,
  });

  final String reportId;
  final HazardReport? initialReport;

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
    mediaUrlFuture = repo.fetchReportMediaUrl(
      widget.reportId,
      userId: widget.initialReport?.createdBy,
    );
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
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Symbols.arrow_back_rounded,
              color: Color(0xFF0F172A),
              size: 22,
            ),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Report Details',
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: FutureBuilder<HazardReport?>(
          initialData: widget.initialReport,
          future: reportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF074E95),
                ),
              );
            }
            if (snapshot.hasError && !snapshot.hasData) {
              return _error(
                'Could not load report: ${snapshot.error}',
                () => setState(_reload),
              );
            }
            final r = snapshot.data;
            if (r == null) {
              return const _Empty(
                icon: Symbols.lock_rounded,
                text: 'Report not found or access denied.',
              );
            }

            final current = selected ?? r.inspectionStatus;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                // 1. Hero Photo Card with Tap to enlarge button
                _buildHeroPhoto(r),
                const SizedBox(height: 14),

                // 2. Main Report Information Card
                _buildMainInfoCard(r),
                const SizedBox(height: 14),

                // 3. Update Status Card
                _buildUpdateStatusCard(r, current),
                const SizedBox(height: 14),

                // 4. Audit History Card
                _buildAuditHistoryCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  // 1. Hero Captured Photo
  Widget _buildHeroPhoto(HazardReport r) {
    return FutureBuilder<String?>(
      future: mediaUrlFuture,
      builder: (context, snapshot) {
        final remoteUrl = snapshot.data ??
            ((r.originalPhotoPath != null && r.originalPhotoPath!.startsWith('http'))
                ? r.originalPhotoPath
                : ((r.thumbnailPhotoPath != null && r.thumbnailPhotoPath!.startsWith('http'))
                    ? r.thumbnailPhotoPath
                    : null));

        final rawLocal = r.originalPhotoPath ??
            r.thumbnailPhotoPath ??
            widget.initialReport?.originalPhotoPath ??
            widget.initialReport?.thumbnailPhotoPath;
        final localPath = (rawLocal != null &&
                !rawLocal.startsWith('http') &&
                File(rawLocal).existsSync())
            ? rawLocal
            : null;

        final hasRemote = remoteUrl != null && remoteUrl.isNotEmpty;
        final hasImage = hasRemote || localPath != null;

        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasRemote)
                Image.network(
                  remoteUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFFF1F5F9),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2.5,
                          color: const Color(0xFF074E95),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => localPath != null
                      ? Image.file(File(localPath), fit: BoxFit.cover)
                      : _fallbackPhotoCard(r),
                )
              else if (localPath != null)
                Image.file(
                  File(localPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallbackPhotoCard(r),
                )
              else if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF074E95),
                  ),
                )
              else
                _fallbackPhotoCard(r),

              // "Tap to enlarge" Pill Button
              if (hasImage)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openFullScreenPreview(
                        context,
                        r,
                        (remoteUrl ?? localPath)!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Symbols.crop_free_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tap to enlarge',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackPhotoCard(HazardReport report) {
    return Container(
      color: const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.image_not_supported_rounded,
            size: 40,
            color: Colors.blueGrey.shade300,
          ),
          const SizedBox(height: 8),
          const Text(
            'No inspection photo for this report',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Main Info Card (Mockup Design)
  Widget _buildMainInfoCard(HazardReport r) {
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: [Bare Hazard Icon + Hazard Title]  ...  [Status Pill]
          Row(
            children: [
              Icon(
                _hazardIcon(r.confirmedHazardType),
                color: const Color(0xFF074E95),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _hazardTitle(r.confirmedHazardType),
                  style: const TextStyle(
                    color: Color(0xFF0A1E3F),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(r.inspectionStatus),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // 7 Metadata Rows with Left Icon Containers
          _buildInfoRow(
            icon: Symbols.warning_amber_rounded,
            label: 'Severity',
            valueWidget: _buildSeverityBadge(r.confirmedSeverity),
          ),
          _buildInfoDivider(),
          _buildInfoRow(
            icon: Symbols.alt_route_rounded,
            label: 'Section',
            valueWidget: Text(
              _sectionName(r.sectionId),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildInfoDivider(),
          _buildInfoRow(
            icon: Symbols.location_on_rounded,
            label: 'Station',
            valueWidget: Text(
              r.nearestStationName ?? 'Kurseong Station',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildInfoDivider(),
          _buildInfoRow(
            icon: Symbols.share_location_rounded,
            label: 'Km Marker',
            valueWidget: Text(
              r.kmMarker == null ? 'Not specified' : _trimKm(r.kmMarker!),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          _buildInfoDivider(),
          _buildInfoRow(
            icon: Symbols.calendar_today_rounded,
            label: 'Created',
            valueWidget: Text(
              _formatDate(r.createdAt),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildInfoDivider(),
          _buildInfoRow(
            icon: Symbols.my_location_rounded,
            label: 'GPS',
            valueWidget: Text(
              r.latitude != null && r.longitude != null
                  ? '${r.latitude!.toStringAsFixed(6)}, ${r.longitude!.toStringAsFixed(6)}'
                  : 'Not captured',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildInfoDivider(),
          _buildInfoRow(
            icon: Symbols.description_rounded,
            label: 'Report ID',
            valueWidget: SelectableText(
              r.id,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
          ),

          // Gangman Note Block (Mockup design)
          if (r.userNote.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildNoteCard(
              icon: Symbols.assignment_rounded,
              title: 'Gangman Note',
              content: r.userNote,
            ),
          ],

          // AI Suggestion Block (Mockup design)
          if (r.aiNote != null && r.aiNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNoteCard(
              icon: Symbols.lightbulb_rounded,
              title: 'AI Suggestion',
              content: r.aiNote!,
              footer: '${r.aiProvider.name} • ${r.aiModel ?? "Gemma 4 E2B"}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF074E95),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return const Divider(
      height: 16,
      thickness: 1,
      color: Color(0xFFF1F5F9),
    );
  }

  Widget _buildNoteCard({
    required IconData icon,
    required String title,
    required String content,
    String? footer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF074E95),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A1E3F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          if (footer != null && footer.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              footer,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. Update Status Card (Mockup Image 2)
  Widget _buildUpdateStatusCard(HazardReport r, InspectionStatus current) {
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Edit icon + "Update Status"
          Row(
            children: [
              const Icon(
                Symbols.edit_rounded,
                color: Color(0xFF074E95),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Update Status',
                style: TextStyle(
                  color: Color(0xFF0A1E3F),
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Outlined Dropdown with Floating Label
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Inspection Status',
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF074E95), width: 1.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<InspectionStatus>(
                value: current,
                isExpanded: true,
                icon: const Icon(
                  Symbols.arrow_drop_down_rounded,
                  color: Color(0xFF0F172A),
                ),
                items: InspectionStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          _statusLabel(s),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (s) => setState(() => selected = s),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Primary Save Status Button
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: saving || current == r.inspectionStatus
                  ? null
                  : () => _save(r),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF074E95),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.save_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Status',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Audit History Card (Mockup Image 2)
  Widget _buildAuditHistoryCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: historyFuture,
      builder: (context, history) {
        if (history.connectionState == ConnectionState.waiting &&
            !history.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(24),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF074E95)),
            ),
          );
        }

        final rows = history.data ?? [];

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
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: History icon + "Audit History"
              Row(
                children: [
                  const Icon(
                    Symbols.history_rounded,
                    color: Color(0xFF074E95),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Audit History',
                    style: TextStyle(
                      color: Color(0xFF0A1E3F),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (history.hasError)
                Text(
                  'Could not load history: ${history.error}',
                  style: const TextStyle(color: Color(0xFFDC2626)),
                )
              else if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No status changes recorded yet.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final h = rows[index];
                    final isLast = index == rows.length - 1;
                    return _buildTimelineItem(h, isLast: isLast);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> h, {required bool isLast}) {
    final from = h['from_status'] == null
        ? 'Initial'
        : _humanize('${h['from_status']}');
    final to = h['to_status'] == null
        ? 'Acknowledged'
        : _humanize('${h['to_status']}');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Line & Dot Indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF074E95),
                      width: 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Content Box
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Transition Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$from → $to',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'By ${h['changed_by'] ?? 'unknown'}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRaw(h['created_at']),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (h['comment'] != null && '${h['comment']}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${h['comment']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                  if (!isLast) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(InspectionStatus status) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case InspectionStatus.open:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        icon = Symbols.error_outline_rounded;
        label = 'Open';
        break;
      case InspectionStatus.acknowledged:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Symbols.visibility_rounded;
        label = 'Acknowledged';
        break;
      case InspectionStatus.inspectionRequired:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        icon = Symbols.build_rounded;
        label = 'Inspection Required';
        break;
      case InspectionStatus.resolved:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        icon = Symbols.check_circle_rounded;
        label = 'Resolved';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(Severity severity) {
    Color bg;
    Color fg;
    String label;

    switch (severity) {
      case Severity.low:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Low';
        break;
      case Severity.medium:
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFF854D0E);
        label = 'Medium';
        break;
      case Severity.high:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'High';
        break;
      case Severity.critical:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'Critical';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }

  IconData _hazardIcon(HazardType type) {
    switch (type) {
      case HazardType.trackDefect:
        return Symbols.train_rounded;
      case HazardType.slip:
        return Symbols.landscape_rounded;
      case HazardType.rockfall:
        return Symbols.warning_amber_rounded;
      case HazardType.blockedDrain:
        return Symbols.water_damage_rounded;
      case HazardType.damagedWall:
        return Symbols.construction_rounded;
      case HazardType.vegetation:
        return Symbols.park_rounded;
      case HazardType.other:
        return Symbols.warning_rounded;
    }
  }

  String _hazardTitle(HazardType type) {
    switch (type) {
      case HazardType.trackDefect:
        return 'Track Defect';
      case HazardType.slip:
        return 'Landslip / Mudslide';
      case HazardType.rockfall:
        return 'Rockfall';
      case HazardType.blockedDrain:
        return 'Blocked Drain';
      case HazardType.damagedWall:
        return 'Damaged Wall';
      case HazardType.vegetation:
        return 'Vegetation Overgrowth';
      case HazardType.other:
        return 'Other Hazard';
    }
  }

  void _openFullScreenPreview(
    BuildContext context,
    HazardReport report,
    String photoUrl,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _AdminFullScreenImageViewer(
            photoUrl: photoUrl,
            report: report,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _AdminFullScreenImageViewer extends StatefulWidget {
  final String photoUrl;
  final HazardReport report;

  const _AdminFullScreenImageViewer({
    required this.photoUrl,
    required this.report,
  });

  @override
  State<_AdminFullScreenImageViewer> createState() =>
      _AdminFullScreenImageViewerState();
}

class _AdminFullScreenImageViewerState
    extends State<_AdminFullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _showOverlays = true;

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  String _getReportTitle() {
    switch (widget.report.confirmedHazardType) {
      case HazardType.damagedWall:
        return 'Damaged Retaining Wall Photo';
      case HazardType.rockfall:
        return 'Rockfall / Fallen Debris Photo';
      case HazardType.slip:
        return 'Landslip / Mudslide Photo';
      case HazardType.blockedDrain:
        return 'Blocked Catchwater Drain Photo';
      case HazardType.trackDefect:
        return 'Track Defect / Rail Gap Photo';
      case HazardType.vegetation:
        return 'Track Obstruction / Vegetation Photo';
      case HazardType.other:
        return 'Track Issue Photo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final kmText =
        'Km ${(widget.report.kmMarker ?? 51.0).toStringAsFixed(1)} • ${widget.report.nearestStationName ?? "Kurseong Station"}';

    final isNetwork = widget.photoUrl.startsWith('http://') ||
        widget.photoUrl.startsWith('https://');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: _showOverlays
            ? AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.75),
                elevation: 0,
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                ),
                leading: IconButton(
                  icon: const Icon(
                    Symbols.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                titleSpacing: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getReportTitle(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kmText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            : null,
        body: GestureDetector(
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: _handleDoubleTap,
          onTap: () {
            setState(() {
              _showOverlays = !_showOverlays;
            });
          },
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: Center(
                child: isNetwork
                    ? Image.network(
                        widget.photoUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Symbols.broken_image_rounded,
                                size: 64,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Photo could not be loaded from remote server',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.file(
                        File(widget.photoUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Symbols.broken_image_rounded,
                                size: 64,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Photo could not be loaded from device',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

/// White rounded list card with an optional header. Rows get dividers.
class _Panel extends StatelessWidget {
  const _Panel({this.icon, this.title, required this.rows});
  final IconData? icon;
  final String? title;
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
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

/// A 2-column grid of tappable status tiles.
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

    Widget tile(InspectionStatus s) {
      final Color bg;
      final Color border;
      final Color iconColor;
      final Color textColor;
      final IconData icon;
      final bool showDot;

      switch (s) {
        case InspectionStatus.open:
          bg = const Color(0xFFFEF2F2);
          border = const Color(0xFFFEE2E2);
          iconColor = const Color(0xFFDC2626);
          textColor = const Color(0xFF991B1B);
          icon = Symbols.error_rounded;
          showDot = (counts[s] ?? 0) > 0;
        case InspectionStatus.acknowledged:
          bg = const Color(0xFFFFFBEB);
          border = const Color(0xFFFEF3C7);
          iconColor = const Color(0xFFD97706);
          textColor = const Color(0xFF92400E);
          icon = Symbols.visibility_rounded;
          showDot = (counts[s] ?? 0) > 0;
        case InspectionStatus.inspectionRequired:
          bg = const Color(0xFFFFF7ED);
          border = const Color(0xFFFFEDD5);
          iconColor = const Color(0xFFEA580C);
          textColor = const Color(0xFF9A3412);
          icon = Symbols.build_circle_rounded;
          showDot = (counts[s] ?? 0) > 0;
        case InspectionStatus.resolved:
          bg = const Color(0xFFF0FDF4);
          border = const Color(0xFFDCFCE7);
          iconColor = const Color(0xFF16A34A);
          textColor = const Color(0xFF166534);
          icon = Symbols.check_circle_rounded;
          showDot = false;
      }

      return Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelect(s),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: iconColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          labelOf(s),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    if (showDot) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${counts[s] ?? 0}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.0,
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
          for (var i = 0; i < all.length; i += 2)
            Padding(
              padding: EdgeInsets.only(top: i > 0 ? 10 : 0),
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
          child: const Icon(Symbols.alt_route_rounded, color: _C.brand, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: _C.ink,
            ),
          ),
        ),
        Text(
          '$count ${count == 1 ? 'report' : 'reports'}',
          style: const TextStyle(fontSize: 12.5, color: _C.muted),
        ),
      ],
    ),
  );
}

class _RecentReportsCard extends StatelessWidget {
  const _RecentReportsCard({
    required this.reports,
    required this.onTapReport,
    required this.onViewAll,
  });

  final List<HazardReport> reports;
  final ValueChanged<HazardReport> onTapReport;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
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
              const Row(
                children: [
                  Icon(
                    Symbols.article_rounded,
                    color: Color(0xFF074E95),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Recent Reports',
                    style: TextStyle(
                      color: Color(0xFF0A1E3F),
                      fontSize: 17.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF074E95),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
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

          if (reports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No reports available.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                ),
              ),
            )
          else
            for (int i = 0; i < reports.length; i++) ...[
              if (i > 0)
                const Divider(
                  color: Color(0xFFF1F5F9),
                  height: 20,
                  thickness: 1.2,
                ),
              _buildReportItem(reports[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildReportItem(HazardReport report) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTapReport(report),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 62,
                  height: 44,
                  child: _ReportThumbnail(report: report),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _humanize(report.confirmedHazardType.name),
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
                            _locationLabel(report),
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
                            _formatDate(report.createdAt),
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
              _StatusPill(status: report.inspectionStatus, compact: true),
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
}

class _ReportThumbnail extends ConsumerStatefulWidget {
  const _ReportThumbnail({required this.report});
  final HazardReport report;

  @override
  ConsumerState<_ReportThumbnail> createState() => _ReportThumbnailState();
}

class _ReportThumbnailState extends ConsumerState<_ReportThumbnail> {
  static final Map<String, String> _urlCache = {};
  String? _resolvedUrl;
  String? _localPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkUrl();
  }

  @override
  void didUpdateWidget(covariant _ReportThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.id != widget.report.id) {
      _checkUrl();
    }
  }

  void _checkUrl() {
    final rep = widget.report;
    final path = rep.thumbnailPhotoPath ?? rep.originalPhotoPath;

    // 1. Direct local file if present on this device
    if (path != null && !path.startsWith('http') && File(path).existsSync()) {
      _localPath = path;
      return;
    }

    // 2. Direct Supabase network/signed URL
    if (path != null && (path.startsWith('http://') || path.startsWith('https://'))) {
      _resolvedUrl = path;
      return;
    }

    // 4. In-memory cache of signed Supabase URL
    if (_urlCache.containsKey(rep.id)) {
      _resolvedUrl = _urlCache[rep.id];
      return;
    }

    // 5. Fetch signed URL directly from Supabase
    _loading = true;
    ref.read(adminRepositoryProvider).fetchReportMediaUrl(rep.id, userId: rep.createdBy).then((url) {
      if (mounted) {
        if (url != null && url.isNotEmpty) {
          _urlCache[rep.id] = url;
        }
        setState(() {
          _resolvedUrl = url;
          _loading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rep = widget.report;

    // 1. Local file if exists
    if (_localPath != null && File(_localPath!).existsSync()) {
      return Image.file(
        File(_localPath!),
        width: 62,
        height: 44,
        fit: BoxFit.cover,
        cacheWidth: 200,
        errorBuilder: (context, error, stackTrace) => _fallback(rep),
      );
    }

    // 2. Network URL (from batch or fetched)
    final url = _resolvedUrl ??
        (rep.thumbnailPhotoPath?.startsWith('http') == true
            ? rep.thumbnailPhotoPath
            : (rep.originalPhotoPath?.startsWith('http') == true
                ? rep.originalPhotoPath
                : null));

    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: 62,
        height: 44,
        fit: BoxFit.cover,
        cacheWidth: 200,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 62,
            height: 44,
            color: const Color(0xFFE8F1FA),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF074E95)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _fallback(rep),
      );
    }

    if (_loading) {
      return Container(
        width: 62,
        height: 44,
        color: const Color(0xFFE8F1FA),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF074E95)),
        ),
      );
    }

    return _fallback(rep);
  }

  Widget _fallback(HazardReport report) {
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

    final leftRail = size.width * 0.28;
    final rightRail = size.width * 0.72;
    canvas.drawLine(Offset(leftRail, 0), Offset(leftRail, size.height), railPaint);
    canvas.drawLine(Offset(rightRail, 0), Offset(rightRail, size.height), railPaint);

    for (double y = 8; y < size.height; y += 12) {
      canvas.drawLine(Offset(leftRail - 6, y), Offset(rightRail + 6, y), sleeperPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onTap});
  final HazardReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 62,
                  height: 44,
                  child: _ReportThumbnail(report: report),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _humanize(report.confirmedHazardType.name),
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
                            _locationLabel(report),
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
                            _formatDate(report.createdAt),
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
              _StatusPill(status: report.inspectionStatus, compact: true),
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
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : _C.ink,
      ),
    ),
  );
}

/// White rounded card. Material (not a decorated Container) so ripples show.
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, this.radius = 20});
  final Widget child;
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
      child: child,
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
              fontSize: 11.5,
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
            style: const TextStyle(color: _C.muted, fontSize: 13.5),
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
        const Icon(Symbols.cloud_off_rounded, size: 40, color: _C.muted),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(Symbols.refresh_rounded),
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
  InspectionStatus.open => Symbols.error_rounded,
  InspectionStatus.acknowledged => Symbols.visibility_rounded,
  InspectionStatus.inspectionRequired => Symbols.build_circle_rounded,
  InspectionStatus.resolved => Symbols.check_circle_rounded,
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