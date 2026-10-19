// Home search + filter (app-brief §3 Home): All · Unprayed today · Carried.
// Both persist across nav and prayer modes (it's the same view). Search
// matches the printed name and the alias.
//
// A name stays visible as context when any of its intentions match; a name
// matched by search brings its intentions (filtered) with it.

import '../models/local_date.dart';
import '../models/subject.dart';
import 'carry.dart';
import 'row_status.dart';
import 'subject_tree.dart';

enum HomeFilter { all, unprayedToday, carried }

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
      HomeFilter.unprayedToday => !prayedToday(s, today),
      HomeFilter.carried => showsCarriedMark(s, tree),
    };

List<HomeRow> visibleRows(
  SubjectTree tree, {
  required LocalDate today,
  String query = '',
  HomeFilter filter = HomeFilter.all,
}) {
  final rows = <HomeRow>[];
  for (final name in tree.names) {
    final nameMatchesQuery = matchesQuery(name, query);
    final namePasses = nameMatchesQuery && passesFilter(name, filter, tree, today);
    final intentions = tree
        .intentionsOf(name.id)
        .where((i) => (nameMatchesQuery || matchesQuery(i, query)) && passesFilter(i, filter, tree, today))
        .toList();
    if (!namePasses && intentions.isEmpty) continue;
    rows.add(HomeRow(name, isContext: !namePasses));
    rows.addAll(intentions.map((i) => HomeRow(i, isContext: false)));
  }
  return rows;
}
