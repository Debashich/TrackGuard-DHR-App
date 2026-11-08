import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trackguard_dhr/features/auth/domain/auth_state.dart';
import 'package:trackguard_dhr/features/auth/presentation/auth_controller.dart';
import 'package:trackguard_dhr/features/home/presentation/home_screen.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/app_language.dart';
import 'package:trackguard_dhr/shared/models/app_user.dart';
import 'package:trackguard_dhr/shared/models/user_role.dart';
import 'package:trackguard_dhr/shared/widgets/language_selector_button.dart';

void main() {
  testWidgets(
    'HomeScreen renders TrackGuardAppBar, Report a Problem, Recent Reports card and Helpline',
    (tester) async {
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

      // Verify App Bar: Language button with translate_indic on extreme left, centered title, profile icon on right
      expect(find.byType(LanguageSelectorButton), findsOneWidget);
      expect(find.byIcon(Symbols.translate_indic_rounded), findsOneWidget);
      expect(find.text('TrackGuard DHR'), findsOneWidget);
      expect(find.byIcon(Symbols.person_rounded), findsOneWidget);

      // Verify Report a Problem Button
      expect(find.text('Report a Problem'), findsOneWidget);

      // Verify "My Reports" card has been removed
      expect(find.text('My Reports'), findsNothing);

      // Verify Recent Reports Card Header
      expect(find.text('Recent Reports'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.byIcon(Symbols.article_rounded), findsOneWidget);

      // Verify Recent Reports items
      expect(find.text('Track Obstruction'), findsOneWidget);
      expect(find.text('Track Damage'), findsOneWidget);
      expect(find.text('Landslide / Rockfall'), findsOneWidget);

      // Verify Emergency Control Room / Helpline button
      expect(find.text('Emergency Control Room / Helpline'), findsOneWidget);
      expect(find.byIcon(Symbols.open_in_new_rounded), findsOneWidget);
    },
  );
}

class _MockAuthController extends AuthController {
  final AppUser _user;
  _MockAuthController(this._user);

  @override
  AuthState build() => AuthState.authorizedGangman(_user);
}
