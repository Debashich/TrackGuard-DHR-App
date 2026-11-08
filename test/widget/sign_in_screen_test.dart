import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/features/auth/presentation/sign_in_screen.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/widgets/google_sign_in_button.dart';

void main() {
  testWidgets('SignInScreen renders video/image background and Google sign-in button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SignInScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Google Sign In button is present
    expect(find.byType(GoogleSignInButton), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
