// Selection rules in prayer (subjects.md, prayer-flow.md; decided 2026-10-17):
// - checking an intention also holds its name (both are linked, so the prayer
//   counts toward the name);
// - checking a name does NOT check its intentions;
// - unchecking a name unchecks its intentions;
// - unchecking an intention leaves its name held;
// - a name shows a partial state when only some of its intentions are held.
//
// The current list is a separate toggle (`PrayerSelection.listIncluded`).
//
// Each held item also keeps when it was checked (`checkedAt`, schema-brief
// §12): a data seam sent per item with the prayer; no UI shows it.

import '../models/subject.dart';
import 'subject_tree.dart';

enum HoldState { none, held, partial }

class PrayerSelection {
  const PrayerSelection({this.held = const {}, this.listIncluded = false, this.checkedAt = const {}});

  static const empty = PrayerSelection();

  /// Held subject ids (names and intentions).
  final Set<String> held;
  final bool listIncluded;

  /// When each held item was checked; see [stampedAt].
  final Map<String, DateTime> checkedAt;

  bool isHeld(String id) => held.contains(id);

  bool get isEmpty => held.isEmpty && !listIncluded;

  PrayerSelection withList(bool included) => PrayerSelection(held: held, listIncluded: included, checkedAt: checkedAt);

  /// Records [at] for every held item not yet stamped (a name held along
  /// with its intention gets the same time) and forgets items let go — so an
  /// item checked, unchecked and checked again keeps the last check.
  PrayerSelection stampedAt(DateTime at) => PrayerSelection(
        held: held,
        listIncluded: listIncluded,
        checkedAt: {for (final id in held) id: checkedAt[id] ?? at},
      );

  /// Tap on a row in prayer: hold it, or let it go.
  PrayerSelection toggle(String id, SubjectTree tree) => isHeld(id) ? release(id, tree) : hold(id, tree);

  PrayerSelection hold(String id, SubjectTree tree) {
    final subject = tree[id];
    if (subject == null) return this;
    final next = {...held, id};
    if (subject.isIntention && subject.parentId != null) next.add(subject.parentId!);
    return PrayerSelection(held: next, listIncluded: listIncluded, checkedAt: checkedAt);
  }

  PrayerSelection release(String id, SubjectTree tree) {
    final subject = tree[id];
    final next = {...held}..remove(id);
    if (subject != null && subject.isName) {
      for (final intention in tree.intentionsOf(id)) {
        next.remove(intention.id);
      }
    }
    return PrayerSelection(held: next, listIncluded: listIncluded, checkedAt: checkedAt);
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
