import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/l10n.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class TrackGuardApp extends ConsumerWidget {
  const TrackGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(currentLocaleProvider);

    return MaterialApp.router(
      title: 'TrackGuard DHR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => _AppFocusScope(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Automatically handles soft keyboard dismissal and tapping outside of text
/// inputs across all screens in the application.
class _AppFocusScope extends StatefulWidget {
  const _AppFocusScope({required this.child});
  final Widget child;

  @override
  State<_AppFocusScope> createState() => _AppFocusScopeState();
}

class _AppFocusScopeState extends State<_AppFocusScope>
    with WidgetsBindingObserver {
  double _lastBottomInset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final bottomInset = views.first.viewInsets.bottom;
    // When keyboard is dismissed (e.g. via Android system back button),
    // automatically unfocus any active text field so the cursor stops blinking.
    if (_lastBottomInset > 0.0 && bottomInset == 0.0) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _lastBottomInset = bottomInset;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null && currentFocus.context?.mounted == true) {
          try {
            final renderBox = currentFocus.context!.findRenderObject();
            if (renderBox is RenderBox && renderBox.hasSize) {
              final globalOrigin = renderBox.localToGlobal(Offset.zero);
              final bounds = globalOrigin & renderBox.size;
              if (!bounds.contains(event.position)) {
                currentFocus.unfocus();
              }
            }
          } catch (_) {}
        }
      },
      child: widget.child,
    );
  }
}
