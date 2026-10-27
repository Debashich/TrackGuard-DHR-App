import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/features/auth/presentation/sign_in_screen.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';

void main() {
  testWidgets('SignInScreen renders branding and sign-in buttons', (
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

    // Verify Title & Branding
    expect(find.text('TRACKGUARD DHR'), findsOneWidget);
    expect(find.byIcon(Icons.train_rounded), findsOneWidget);

    // Verify Google Sign In button
    expect(find.text('Sign In with Google'), findsOneWidget);

    // Verify Dev buttons
    expect(find.text('Developer Sign In (Gangman)'), findsOneWidget);
    expect(find.text('Developer Sign In (Admin)'), findsOneWidget);
  });
}
