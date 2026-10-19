// Selection rules in prayer (subjects.md, prayer-flow.md; decided 2026-10-17):
// - checking an intention also holds its name (both are linked, so the prayer
//   counts toward the name);
// - checking a name does NOT check its intentions;
// - unchecking a name unchecks its intentions;
// - unchecking an intention leaves its name held;
// - a name shows a partial state when only some of its intentions are held.
//
// The current list is a separate toggle (`PrayerSelection.listIncluded`).

import '../models/subject.dart';
import 'subject_tree.dart';

enum HoldState { none, held, partial }

class PrayerSelection {
  const PrayerSelection({this.held = const {}, this.listIncluded = false});

  static const empty = PrayerSelection();

  /// Held subject ids (names and intentions).
  final Set<String> held;
  final bool listIncluded;

  bool isHeld(String id) => held.contains(id);

  bool get isEmpty => held.isEmpty && !listIncluded;

  PrayerSelection withList(bool included) => PrayerSelection(held: held, listIncluded: included);

  /// Tap on a row in prayer: hold it, or let it go.
  PrayerSelection toggle(String id, SubjectTree tree) =>
      isHeld(id) ? release(id, tree) : hold(id, tree);

  PrayerSelection hold(String id, SubjectTree tree) {
    final subject = tree[id];
    if (subject == null) return this;
    final next = {...held, id};
    if (subject.isIntention && subject.parentId != null) next.add(subject.parentId!);
    return PrayerSelection(held: next, listIncluded: listIncluded);
  }

  PrayerSelection release(String id, SubjectTree tree) {
    final subject = tree[id];
    final next = {...held}..remove(id);
    if (subject != null && subject.isName) {
      for (final intention in tree.intentionsOf(id)) {
        next.remove(intention.id);
      }
    }
    return PrayerSelection(held: next, listIncluded: listIncluded);
  }

  /// What a row's check shows.
  HoldState stateOf(String id, SubjectTree tree) {
    if (!isHeld(id)) return HoldState.none;
    final subject = tree[id];
    if (subject == null || subject.kind == SubjectKind.intention) return HoldState.held;
    final intentions = tree.intentionsOf(id);
    final heldCount = intentions.where((i) => isHeld(i.id)).length;
    return heldCount > 0 && heldCount < intentions.length ? HoldState.partial : HoldState.held;
  }
}
