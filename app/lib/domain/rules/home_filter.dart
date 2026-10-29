// Home search + filter (design-direction.md §4): All · Still to hold ·
// Carried. Both persist across nav and prayer modes (it's the same view).
// Search matches the printed name and the alias.
//
// A name stays visible as context when any of its intentions match; a name
// matched by search brings its intentions (filtered) with it.
//
// Counts (the filter menu only, never on Home) are items: names and
// intentions that pass the filter, search aside.

import '../models/local_date.dart';
import '../models/subject.dart';
import 'carry.dart';
import 'row_status.dart';
import 'subject_tree.dart';

enum HomeFilter { all, stillToHold, carried }

class HomeRow {
  const HomeRow(this.subject, {required this.isContext});

  final Subject subject;

  /// Shown only as the parent of a matching intention.
  final bool isContext;

  bool get isIntention => subject.isIntention;
}

bool matchesQuery(Subject s, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return s.publicName.toLowerCase().contains(q) || (s.alias?.toLowerCase().contains(q) ?? false);
}

bool passesFilter(Subject s, HomeFilter filter, SubjectTree tree, LocalDate today) => switch (filter) {
      HomeFilter.all => true,
      HomeFilter.stillToHold => !prayedToday(s, today),
      HomeFilter.carried => showsCarriedMark(s, tree),
    };

/// [keep]: ids that pass the filter regardless (rows lingering after Amen
/// under Still to hold, before they fold away).
List<HomeRow> visibleRows(
  SubjectTree tree, {
  required LocalDate today,
  String query = '',
  HomeFilter filter = HomeFilter.all,
  Set<String> keep = const {},
}) {
  bool passes(Subject s) => keep.contains(s.id) || passesFilter(s, filter, tree, today);
  final rows = <HomeRow>[];
  for (final name in tree.names) {
    final nameMatchesQuery = matchesQuery(name, query);
    final namePasses = nameMatchesQuery && passes(name);
    final intentions =
        tree.intentionsOf(name.id).where((i) => (nameMatchesQuery || matchesQuery(i, query)) && passes(i)).toList();
    if (!namePasses && intentions.isEmpty) continue;
    rows.add(HomeRow(name, isContext: !namePasses));
    rows.addAll(intentions.map((i) => HomeRow(i, isContext: false)));
  }
  return rows;
}

/// How many items (names and intentions) [filter] keeps, search aside.
int filterCount(SubjectTree tree, HomeFilter filter, LocalDate today) {
  var n = 0;
  for (final name in tree.names) {
    if (passesFilter(name, filter, tree, today)) n++;
    for (final i in tree.intentionsOf(name.id)) {
      if (passesFilter(i, filter, tree, today)) n++;
    }
  }
  return n;
}

/// The Carried view holds only you (your name and your own intentions) or
/// nothing: Home then teaches what Carried means (design-direction.md §6).
bool carriedShowsOnlyYou(List<HomeRow> rows, SubjectTree tree) {
  final self = tree.self;
  return rows.every((r) => r.subject.isSelf || (self != null && r.subject.parentId == self.id));
}

/// Items [query] matches under All (context rows aside): what clearing the
/// filter would reveal.
int matchesInAll(SubjectTree tree, String query, LocalDate today) =>
    visibleRows(tree, today: today, query: query).where((r) => !r.isContext).length;
