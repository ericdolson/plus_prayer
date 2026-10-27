import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/appearance.dart';
import '../state/prayer_session.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/pp_theme.dart';
import 'router.dart';

class PlusPrayerApp extends HookConsumerWidget {
  const PlusPrayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = useMemoized(buildRouter);
    useEffect(() => router.dispose, [router]);

    // Backgrounding (prayer-flow.md): the session notes when the app leaves
    // and decides on return whether to resume quietly or ask. The write queue
    // retries on every return.
    useOnAppLifecycleStateChange((previous, current) {
      final session = ref.read(prayerSessionProvider.notifier);
      if (current == AppLifecycleState.paused || current == AppLifecycleState.hidden) {
        session.onBackground();
      } else if (current == AppLifecycleState.resumed) {
        session.onForeground();
        ref.read(writeQueueProvider).flush();
      }
    });

    // A draft this device left open (the app was killed mid-prayer), once the
    // list and subjects are known.
    final ready = ref.watch(subjectTreeProvider.select((v) => v.hasValue)) &&
        ref.watch(currentListProvider.select((v) => v.hasValue));
    useEffect(() {
      if (ready) ref.read(prayerSessionProvider.notifier).restoreDraft();
      return null;
    }, [ready]);

    // Built in build, not memoized: hooks survive a hot reload, so a memoized
    // theme would keep stale tokens until a restart. Cheap, and ThemeData
    // compares by value, so a rebuild with the same tokens changes nothing.
    return MaterialApp.router(
      onGenerateTitle: (context) => L10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: const Duration(milliseconds: 200),
      // Screens without an AppBar (Home) still get status bar icons that read
      // on the current ground.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlayStyle(context.pp.colors),
        child: child!,
      ),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      routerConfig: router,
    );
  }
}
