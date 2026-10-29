import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/features/auth/domain/auth_state.dart';
import 'package:trackguard_dhr/features/auth/presentation/auth_controller.dart';
import 'package:trackguard_dhr/features/profile/presentation/profile_screen.dart';
import 'package:trackguard_dhr/features/report_detail/presentation/gangman_report_detail_screen.dart';
import 'package:trackguard_dhr/features/reports/data/report_repository.dart';
import 'package:trackguard_dhr/features/reports/domain/report_repository_provider.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/ai_provider.dart';
import 'package:trackguard_dhr/shared/models/app_language.dart';
import 'package:trackguard_dhr/shared/models/app_user.dart';
import 'package:trackguard_dhr/shared/models/hazard_report.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
import 'package:trackguard_dhr/shared/models/inspection_status.dart';
import 'package:trackguard_dhr/shared/models/location_source.dart';
import 'package:trackguard_dhr/shared/models/report_draft.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';
import 'package:trackguard_dhr/shared/models/sync_status.dart';
import 'package:trackguard_dhr/shared/models/sync_summary.dart';
import 'package:trackguard_dhr/shared/models/user_role.dart';
import 'package:trackguard_dhr/shared/widgets/logout_confirmation.dart';
import 'package:trackguard_dhr/shared/widgets/role_navigation_drawer.dart';

class _MockAuthController extends AuthController {
  final AppUser _user;
  bool signedOut = false;

  _MockAuthController(this._user);

  @override
  AuthState build() {
    if (_user.role == UserRole.admin) {
      return AuthState.authorizedAdmin(_user);
    }
    return AuthState.authorizedGangman(_user);
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    state = AuthState.unauthenticated();
  }
}

class _MockReportRepository implements ReportRepository {
  final HazardReport? mockReport;

  _MockReportRepository([this.mockReport]);

  @override
  Future<void> saveDraft(ReportDraft draft) async {}

  @override
  Future<ReportDraft?> getDraft() async => null;

  @override
  Future<void> clearDraft() async {}

  @override
  Future<void> saveReport(HazardReport report) async {}

  @override
  Future<HazardReport?> getReportById(String id) async => mockReport;

  @override
  Future<List<HazardReport>> getLocalReports() async =>
      mockReport != null ? [mockReport!] : [];

  @override
  Future<int> getPendingCount() async => 0;

  @override
  Stream<List<HazardReport>> watchLocalReports() {
    return Stream.value(mockReport != null ? [mockReport!] : []);
  }
}

void main() {
  final testGangman = AppUser(
    id: 'gangman-001',
    fullName: 'Ramesh Sharma',
    email: 'ramesh.sharma@dhr.railways.gov.in',
    role: UserRole.gangman,
    assignedSection: 'kurseong-ghum',
    preferredLanguage: AppLanguage.en,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testAdmin = AppUser(
    id: 'admin-001',
    fullName: 'Debashish Banerjee',
    email: 'admin@dhr.railways.gov.in',
    role: UserRole.admin,
    assignedSection: null,
    preferredLanguage: AppLanguage.en,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('ProfileScreen Widget Tests', () {
    testWidgets('Renders Gangman user details, section, and language options', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _MockAuthController(testGangman),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Profile details
      expect(find.text('Ramesh Sharma'), findsAtLeastNWidgets(1));
      expect(
        find.text('ramesh.sharma@dhr.railways.gov.in'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Gangman'), findsAtLeastNWidgets(1));
      expect(find.text('Kurseong → Ghum'), findsAtLeastNWidgets(1));

      // Language chips
      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिंदी (Hindi)'), findsOneWidget);
      expect(find.text('বাংলা (Bengali)'), findsOneWidget);
      expect(find.text('नेपाली (Nepali)'), findsOneWidget);

      // Action buttons
      expect(find.text('RETURN TO DASHBOARD'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsOneWidget);
    });

    testWidgets('Renders Admin user details with admin role title', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _MockAuthController(testAdmin),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Debashish Banerjee'), findsAtLeastNWidgets(1));
      expect(find.text('admin@dhr.railways.gov.in'), findsAtLeastNWidgets(1));
      expect(find.text('Supervisor / Admin'), findsAtLeastNWidgets(1));
      expect(find.text('All DHR Alignment'), findsAtLeastNWidgets(1));
    });
  });

  group('LogoutConfirmationDialog Widget Tests', () {
    testWidgets(
      'Shows warning about pending reports remaining locally and signs out when confirmed',
      (tester) async {
        final mockAuth = _MockAuthController(testGangman);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(() => mockAuth),
              syncSummaryProvider.overrideWithValue(
                const SyncSummary(
                  pendingCount: 2,
                  syncingCount: 0,
                  failedCount: 1,
                  syncedCount: 5,
                  conflictCount: 0,
                  isOnline: false,
                ),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () =>
                          showLogoutConfirmationDialog(context, ref),
                      child: const Text('TRIGGER_LOGOUT'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Tap trigger button to open dialog
        await tester.tap(find.text('TRIGGER_LOGOUT'));
        await tester.pumpAndSettle();

        // Verify dialog contents
        expect(find.text('Confirm Sign Out'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);

        // Check for warning icon and pending report message
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.textContaining('waiting to synchronize'), findsOneWidget);
        expect(find.textContaining('remain safely stored'), findsOneWidget);

        // Confirm Sign Out
        final signOutButton = find.widgetWithText(ElevatedButton, 'Sign Out');
        expect(signOutButton, findsOneWidget);
        await tester.tap(signOutButton);
        await tester.pumpAndSettle();

        expect(mockAuth.signedOut, isTrue);
      },
    );

    testWidgets('Can cancel logout dialog without signing out', (tester) async {
      final mockAuth = _MockAuthController(testGangman);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith(() => mockAuth)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => showLogoutConfirmationDialog(context, ref),
                    child: const Text('TRIGGER_LOGOUT'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('TRIGGER_LOGOUT'));
      await tester.pumpAndSettle();

      // Tap "Stay Signed In" (the cancel action)
      expect(find.text('Stay Signed In'), findsOneWidget);
      await tester.tap(find.text('Stay Signed In'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Sign Out'), findsNothing);
      expect(mockAuth.signedOut, isFalse);
    });
  });

  group('RoleNavigationDrawer Widget Tests', () {
    testWidgets('Renders Gangman destinations and hides Admin Dashboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _MockAuthController(testGangman),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              drawer: RoleNavigationDrawer(currentRoute: '/gangman/home'),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Gangman destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('New Report'), findsOneWidget);
      expect(find.text('My Reports'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Must not show Admin Dashboard
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('Renders Admin destinations and hides New Hazard Report', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _MockAuthController(testAdmin),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              drawer: RoleNavigationDrawer(currentRoute: '/admin/dashboard'),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Admin destinations
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Must not show New Report or My Reports
      expect(find.text('New Report'), findsNothing);
      expect(find.text('My Reports'), findsNothing);
    });
  });

  group('GangmanReportDetailScreen Widget Tests', () {
    final mockReport = HazardReport(
      id: 'rep-test-001',
      createdBy: 'gangman-001',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      latitude: 26.8833,
      longitude: 88.2833,
      gpsAccuracyMeters: 4.5,
      locationSource: LocationSource.gps,
      distanceToAlignmentKm: 0.05,
      kmMarker: 51.2,
      sectionId: 'kurseong-ghum',
      nearestStationName: 'Tung',
      confirmedHazardType: HazardType.rockfall,
      confirmedSeverity: Severity.high,
      userNote: 'Rocks fallen on the outer rail after heavy rainfall.',
      aiSuggestedHazardType: HazardType.rockfall,
      aiSuggestedSeverity: Severity.high,
      aiNote: 'Rock debris blocking track near km 51.2.',
      aiProvider: AiProvider.offlineGemma,
      aiModel: 'Gemma 4 E2B',
      aiConfidence: 0.92,
      inspectionStatus: InspectionStatus.open,
      syncStatus: SyncStatus.synced,
      originalPhotoPath: '/non/existent/path.jpg',
    );

    testWidgets(
      'Renders report metadata, missing photo placeholder, and no supervisor actions',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(
                () => _MockAuthController(testGangman),
              ),
              reportRepositoryProvider.overrideWithValue(
                _MockReportRepository(mockReport),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: GangmanReportDetailScreen(reportId: 'rep-test-001'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Confirmed details
        expect(find.text('Rockfall / Fallen Debris'), findsWidgets);
        expect(find.text('Tung • Km 51.2'), findsOneWidget);
        expect(
          find.text('Rocks fallen on the outer rail after heavy rainfall.'),
          findsOneWidget,
        );

        // Photo placeholder when file does not exist
        expect(find.text('Photo not found on device'), findsOneWidget);

        // AI suggestion audit card
        expect(find.text('AI ADVISORY METADATA'), findsOneWidget);
        expect(find.text('Gemma 4 E2B'), findsOneWidget);

        // Strict verification: Gangman screen must NOT have admin status mutation actions
        expect(find.text('Acknowledge'), findsNothing);
        expect(find.text('Require Inspection'), findsNothing);
        expect(find.text('Resolve Hazard'), findsNothing);
      },
    );
  });
}
