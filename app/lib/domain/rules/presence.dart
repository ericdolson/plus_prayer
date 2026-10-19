// The quiet presence line on Home (presence-live.md). Count only, never who.
// Ladder: prayingNow ≥ threshold → live; else prayedLastHour ≥ threshold →
// last hour; else prayedToday ≥ threshold → today; else hidden. Never 0.

import '../models/live.dart';

enum PresenceWindow { now, lastHour, today }

class PresenceLine {
  const PresenceLine(this.window, this.count);

  final PresenceWindow window;
  final int count;
}

PresenceLine? presenceLine(LiveStats stats, int threshold) {
  if (stats.prayingNow >= threshold) return PresenceLine(PresenceWindow.now, stats.prayingNow);
  if (stats.prayedLastHour >= threshold) return PresenceLine(PresenceWindow.lastHour, stats.prayedLastHour);
  if (stats.prayedToday >= threshold) return PresenceLine(PresenceWindow.today, stats.prayedToday);
  return null;
}

/// Others in prayer alongside the user, for the prayer bar ("with 212
/// others"); null when the live count is under the display threshold.
int? othersInPrayer(LiveStats stats, int threshold) {
  if (stats.prayingNow < threshold) return null;
  // The user's own presence is part of prayingNow once it has synced.
  return stats.prayingNow - 1;
}
