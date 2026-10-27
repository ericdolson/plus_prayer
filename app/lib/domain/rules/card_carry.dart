// The community card's two lines (design-direction.md §6, 2026-10-24):
//
//   avatar row = yours on TODAY's list   "You, Dad + 3 are on List 52"
//   status     = TOMORROW, from the gate "Pray to carry them onto List 53"
//
// The gate (list-lifecycle.md): a prayer with the current list, started before
// its cutoff, carries you and your carried names onto the next list. (The ~30 h
// window is a server-side safety net; the next cutoff isn't known ahead, so the
// app never promises it.) Only differences between today and tomorrow are
// named: who joins, who isn't carried.

import '../models/local_date.dart';
import '../models/prayer.dart';
import '../models/prayer_list.dart';
import '../models/subject.dart';
import '../models/user_header.dart';
import 'carry.dart';
import 'streak.dart';
import 'subject_tree.dart';

enum TomorrowStatus {
  /// A qualifying prayer for the next list exists: "They'll be on List 53".
  covered,

  /// Prayed with the list today, but it has flipped since:
  /// "Your next prayer carries them onto List 54".
  nextPrayerCarries,

  /// "Pray to carry them onto List 53".
  prayToCarry,
}

class CardCarry {
  const CardCarry({
    required this.onToday,
    required this.status,
    this.joining = const [],
    this.notCarried = const [],
  });

  /// Your names printed on today's list, you first, then in your order.
  /// Empty when you aren't on it (new user): no avatar row.
  final List<Subject> onToday;
  final TomorrowStatus status;

  /// Carried tomorrow but not on today's list: "Mom joins you on List 53".
  final List<Subject> joining;

  /// On today's list but not carried tomorrow: "Aunt Jo isn't carried on
  /// List 53".
  final List<Subject> notCarried;

  /// Speak about "you" rather than "them": nobody of yours but you on today's
  /// list (or not even you).
  bool get aboutYouOnly => onToday.every((s) => s.isSelf);
}

/// True when the next list is already earned: the server has a prayer with
/// [list], or this device has one queued that started before the cutoff.
bool nextListCovered(CurrentList list, MyListStatus? status, List<NewPrayer> local) {
  if (status != null && status.listId == list.id && status.prayersWithList > 0) return true;
  final closesAt = list.closesAt;
  return local.any((p) => p.communityListId == list.id && (closesAt == null || p.startedAt.isBefore(closesAt)));
}

CardCarry cardCarry({
  required SubjectTree tree,
  required CurrentList list,
  required MyListStatus? status,
  required List<NewPrayer> localPrayers,
  required UserHeader? header,
  required LocalDate today,
}) {
  final printedIds = {
    if (status != null && status.listId == list.id)
      for (final e in status.entries)
        if (e.isName && e.subjectId != null) e.subjectId!,
  };
  // Today's names in your order (self first), only those still in your list.
  final onToday = [
    for (final s in tree.names)
      if (printedIds.contains(s.id)) s,
  ];

  final TomorrowStatus tomorrow;
  if (nextListCovered(list, status, localPrayers)) {
    tomorrow = TomorrowStatus.covered;
  } else if (header != null && prayedWithListToday(header, today)) {
    tomorrow = TomorrowStatus.nextPrayerCarries;
  } else {
    tomorrow = TomorrowStatus.prayToCarry;
  }

  final carried = carriedNames(tree);
  final carriedIds = {for (final s in carried) s.id};
  return CardCarry(
    onToday: onToday,
    status: tomorrow,
    joining: onToday.isEmpty
        ? const []
        : [
            for (final s in carried)
              if (!s.isSelf && !printedIds.contains(s.id)) s
          ],
    notCarried: [
      for (final s in onToday)
        if (!s.isSelf && !carriedIds.contains(s.id)) s
    ],
  );
}
