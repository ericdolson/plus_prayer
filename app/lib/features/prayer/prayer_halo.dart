// The prayer halo around a screen that hosts prayer in place (Home, a detail
// page), driven by the app-level session (design-direction.md §7).

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/halo.dart';
import '../../state/prayer_session.dart';

class PrayerHalo extends ConsumerWidget {
  const PrayerHalo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(prayerSessionProvider.select((s) => s.phase));
    return Halo(
      // Reaching closing means an Amen committed the prayer (welcome-back's
      // too): the halo flares, then fades beneath the closing sheet, which
      // doesn't wait for it. Cancel and Discard go straight to idle: a plain
      // fade.
      mode: switch (phase) {
        PrayerPhase.praying || PrayerPhase.invitation => HaloMode.on,
        PrayerPhase.closing => HaloMode.amen,
        PrayerPhase.idle => HaloMode.off,
      },
      child: child,
    );
  }
}
