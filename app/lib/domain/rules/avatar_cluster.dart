// Avatar cluster (screens.md, 2026-10-18): you first, then carried names in
// the user's order. The first one or two are named with their avatar beside
// each name; additional names are tightly overlapped, up to 5 avatars total,
// then "+ N others". Screen readers read every name.

class ClusterLayout<T> {
  const ClusterLayout({required this.named, required this.overlapped, required this.others});

  /// Shown with their name beside the avatar.
  final List<T> named;

  /// Avatars only, overlapped.
  final List<T> overlapped;

  /// "+ N others" beyond the 5 avatars.
  final int others;
}

ClusterLayout<T> layoutCluster<T>(List<T> people, {int maxNamed = 2, int maxAvatars = 5}) {
  final named = people.take(maxNamed).toList();
  final overlapped = people.skip(named.length).take(maxAvatars - named.length).toList();
  return ClusterLayout(
    named: named,
    overlapped: overlapped,
    others: people.length - named.length - overlapped.length,
  );
}
