import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/features/auth/domain/auth_state.dart';
import 'package:trackguard_dhr/features/auth/presentation/auth_controller.dart';
import 'package:trackguard_dhr/features/home/presentation/home_screen.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/app_language.dart';
import 'package:trackguard_dhr/shared/models/app_user.dart';
import 'package:trackguard_dhr/shared/models/user_role.dart';

void main() {
  testWidgets('HomeScreen renders Gangman profile and New Report action', (
    tester,
  ) async {
    final mockUser = AppUser(
      id: 'dhr-gangman-001',
      fullName: 'Ramesh Sharma',
      email: 'ramesh.sharma@dhr.railways.gov.in',
      role: UserRole.gangman,
      assignedSection: 'kurseong-ghum',
      preferredLanguage: AppLanguage.en,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _MockAuthController(mockUser),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Gangman user name & email
    expect(find.text('Ramesh Sharma'), findsOneWidget);
    expect(find.text('ramesh.sharma@dhr.railways.gov.in'), findsOneWidget);
    expect(find.text('GANGMAN'), findsOneWidget);

    // Verify Section
    expect(find.text('Assigned Section: Kurseong → Ghum'), findsOneWidget);

    // Verify New Report Button
    expect(find.text('NEW REPORT'), findsOneWidget);

    // Verify Queue Card
    expect(find.text('Pending Sync Queue'), findsOneWidget);
  });
}

class _MockAuthController extends AuthController {
  final AppUser _user;
  _MockAuthController(this._user);

  @override
  AuthState build() => AuthState.authorizedGangman(_user);
}
