import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/localization/l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/primary_button.dart';
import '../domain/auth_state.dart';
import 'auth_controller.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final isAuthenticating = authState.status == AuthStatus.authenticating;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language, color: AppTheme.primaryAmber),
            tooltip: l10n.selectLanguage,
            onSelected: (lang) {
              ref.read(appLanguageProvider.notifier).setLanguage(lang);
            },
            itemBuilder: (context) => AppLanguage.values.map((lang) {
              final isSelected = lang == currentLang;
              return PopupMenuItem<AppLanguage>(
                value: lang,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppTheme.primaryAmber,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(lang.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding Header
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.train_rounded,
                      size: 48,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.appTitle.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // Error Message if any
                if (authState.status == AuthStatus.authError &&
                    authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.statusRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.statusRed),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Google Sign In
                PrimaryButton(
                  text: l10n.signInGoogle,
                  icon: Icons.account_circle,
                  isLoading: isAuthenticating,
                  onPressed: isAuthenticating
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(),
                ),

                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'DEVELOPMENT ACCESS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Development Gangman Sign In
                OutlinedButton.icon(
                  onPressed: isAuthenticating
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .signInDevelopment(role: UserRole.gangman),
                  icon: const Icon(Icons.engineering_outlined),
                  label: Text(l10n.devSignInGangman),
                ),

                const SizedBox(height: 12),

                // Development Admin Sign In
                OutlinedButton.icon(
                  onPressed: isAuthenticating
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .signInDevelopment(role: UserRole.admin),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: Text(l10n.devSignInAdmin),
                ),

                const SizedBox(height: 32),
                // Offline Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: AppTheme.primaryAmber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.offlineExplanation,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
