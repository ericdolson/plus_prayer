// Monogram avatars (prayer-flow.md): initials on a muted tone. The default
// tone comes from a hash of the subject ID (not the name, so renaming doesn't
// change it); the user can pick another palette index (`avatarTone`).

import 'package:characters/characters.dart';

import '../models/subject.dart';

/// Size of the tone palette; matches the backend's 0–15 range check.
const avatarToneCount = 16;

/// FNV-1a over the id's code units — stable across runs and platforms
/// (`String.hashCode` isn't).
int defaultAvatarTone(String id) {
  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash % avatarToneCount;
}

int avatarToneOf(Subject s) => s.avatarTone ?? defaultAvatarTone(s.id);

/// Up to two initials, any script (grapheme-safe). The self uses the real
/// name, since its alias is always "Me".
String monogramOf(Subject s) => initials(s.isSelf ? s.publicName : s.label);

String initials(String text) {
  final words = text.trim().split(RegExp(r'\s+', unicode: true)).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  String first(String w) => w.characters.first.toUpperCase();
  if (words.length == 1) return first(words.first);
  return first(words.first) + first(words.last);
}
