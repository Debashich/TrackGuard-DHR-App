import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/features/ai/domain/ai_settings.dart';
import 'package:trackguard_dhr/features/ai/presentation/ai_settings_screen.dart';
import 'package:trackguard_dhr/features/report_review/presentation/widgets/ai_suggestion_card.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/ai_analysis_result.dart';
import 'package:trackguard_dhr/shared/models/ai_provider.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';

void main() {
  group('AiSettingsScreen Widget Tests', () {
    testWidgets(
      'Renders all AI modes, status cards, and mandatory confirmation',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AiSettingsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify AI Modes
        expect(find.text('Automatic (Offline-First)'), findsOneWidget);
        expect(find.text('Offline Gemma 4 E2B'), findsOneWidget);
        expect(find.text('Online Gemini Cloud'), findsOneWidget);
        expect(find.text('Manual Classification Only'), findsOneWidget);

        // Verify Gemma Card
        expect(find.text('OFFLINE GEMMA ENGINE'), findsOneWidget);
        expect(find.text('Gemma 4 E2B'), findsOneWidget);

        // Verify Gemini Card
        expect(find.text('GEMINI CLOUD REASONING'), findsOneWidget);
        expect(find.text('Gemini 1.5 Flash (Edge Function)'), findsOneWidget);

        // Verify Mandatory Human Confirmation
        expect(find.text('Human Confirmation Mandatory'), findsOneWidget);
        expect(
          find.textContaining('AI suggestion is advisory only'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Selecting an AI mode updates the selection', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AiSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Offline Gemma mode
      await tester.tap(find.text('Offline Gemma 4 E2B'));
      await tester.pumpAndSettle();

      // Tap Manual Classification mode
      await tester.tap(find.text('Manual Classification Only'));
      await tester.pumpAndSettle();
    });
  });

  group('AiSuggestionCard Widget Tests', () {
    testWidgets('Displays fallback badge and triggers manual/retry callbacks', (
      tester,
    ) async {
      bool manualClicked = false;
      bool retryClicked = false;

      final mockResult = AiAnalysisResult(
        hazardType: HazardType.rockfall,
        severity: Severity.high,
        note: 'Debris noticed on outer curve near Km 64.5.',
        provider: AiProvider.heuristic,
        requestedProvider: AiProvider.offlineGemma,
        fallbackReason:
            'Offline Gemma model not ready. Used heuristic fallback.',
        confidence: 0.75,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AiSuggestionCard(
              aiResult: mockResult,
              isAnalyzing: false,
              onRetry: () => retryClicked = true,
              onSwitchToManual: () => manualClicked = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Suggestion details
      expect(find.text('AI Advisory Suggestion'), findsOneWidget);
      expect(find.text('Heuristic'), findsOneWidget);
      expect(
        find.text('Debris noticed on outer curve near Km 64.5.'),
        findsOneWidget,
      );

      // Tap Switch to Manual
      expect(find.text('Switch to Manual'), findsOneWidget);
      await tester.tap(find.text('Switch to Manual'));
      expect(manualClicked, isTrue);

      // Tap Retry AI Analysis
      expect(find.text('Retry AI Analysis'), findsOneWidget);
      await tester.tap(find.text('Retry AI Analysis'));
      expect(retryClicked, isTrue);
    });

    testWidgets('Displays analyzing indicator when analysis is in progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AiSuggestionCard(
              aiResult: null,
              isAnalyzing: true,
              currentMode: AiMode.offlineGemma,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text('Analyzing with Offline Gemma 4 E2B...'),
        findsOneWidget,
      );
    });
  });
}
