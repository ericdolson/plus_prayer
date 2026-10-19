// Optimistic view: prayers logged on this device that the server may not
// reflect yet (queued offline, or sent but not re-fetched) are folded into
// what Home shows, so "Prayed today" and the streak update the moment Amen is
// said, with or without signal. Folding is idempotent: applying a prayer the
// server already counted changes nothing.

import '../models/prayer.dart';
import '../models/subject.dart';
import '../models/user_header.dart';
import 'streak.dart';

List<Subject> subjectsWithLocalPrayers(List<Subject> subjects, List<NewPrayer> local) {
  if (local.isEmpty) return subjects;
  final byId = {for (final s in subjects) s.id: s};
  final latest = <String, NewPrayer>{};
  for (final p in local) {
    // Holding an intention also links its name (server does the same).
    final ids = {
      ...p.subjectIds,
      for (final id in p.subjectIds)
        if (byId[id]?.parentId != null) byId[id]!.parentId!,
    };
    for (final id in ids) {
      final seen = latest[id];
      if (seen == null || p.localDate.isAfter(seen.localDate)) latest[id] = p;
    }
  }
  return [
    for (final s in subjects)
      if (latest[s.id] case final p? when s.lastPrayed == null || p.localDate.isAfter(s.lastPrayed!))
        s.copyWith(lastPrayed: p.localDate)
      else
        s,
  ];
}

UserHeader headerWithLocalPrayers(UserHeader header, List<NewPrayer> local) {
  final listPrayers = local.where((p) => p.includesList).toList()
    ..sort((a, b) => a.localDate.compareTo(b.localDate));
  var h = header;
  for (final p in listPrayers) {
    h = afterListPrayer(h, p.localDate);
  }
  return h;
}
