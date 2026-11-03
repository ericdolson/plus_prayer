// Avatar cluster (design-direction.md §6, 2026-10-27; one shared component:
// the card, the Amen invitation, Today's list, Your portion). Overlapping
// avatars first, then text that begins with names. Up to 5 people: every
// avatar, and the text counts the rest ("You, Dad + 3"). More: 4 avatars and
// a "+N" disc, and the text doesn't count ("You, Dad and others"). The count
// appears exactly once. Screen readers read every name.

class ClusterLayout<T> {
  const ClusterLayout({required this.avatars, required this.overflow, required this.named, required this.counted});

  /// Shown as overlapping avatars, in order.
  final List<T> avatars;

  /// The "+N" disc after the avatars; 0 = no disc.
  final int overflow;

  /// Named in the text: the first one or two.
  final List<T> named;

  /// Counted in the text after the names ("+ 3"); 0 when there's a disc or
  /// nobody beyond the names.
  final int counted;
}

ClusterLayout<T> layoutCluster<T>(List<T> people, {int maxAvatars = 5, int maxNamed = 2}) {
  final fits = people.length <= maxAvatars;
  final avatars = fits ? people : people.take(maxAvatars - 1).toList();
  final named = people.take(maxNamed).toList();
  return ClusterLayout(
    avatars: avatars,
    overflow: people.length - avatars.length,
    named: named,
    counted: fits ? people.length - named.length : 0,
  );
}

/// How many overlapping discs of [size], each [step] after the last, fit in
/// [width].
int discCapacity(double width, double size, double step) => width < size ? 0 : ((width - size) / step).floor() + 1;

/// The card's full-width fill (design-direction.md §6, 2026-11-02): everyone
/// when they fit; otherwise as many as fit less one, then a "+N" disc for the
/// rest. Measured, never a fixed cap.
({int shown, int overflow}) fillRow(int people, int capacity) {
  if (people <= capacity) return (shown: people, overflow: 0);
  final shown = capacity > 0 ? capacity - 1 : 0;
  return (shown: shown, overflow: people - shown);
}
