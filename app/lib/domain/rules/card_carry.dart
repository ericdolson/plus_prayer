// The community card's you block (design-direction.md §6, 2026-11-02):
//
//   avatar row = your carried people (who goes onto the next list)
//   status     = the next list, from the gate "Pray to carry them onto List 53"
//
// The gate (list-lifecycle.md): a prayer with the current list, started before
// its cutoff, carries you and your carried names onto the next list. (The ~30 h
// window is a server-side safety net; the next cutoff isn't known ahead, so the
// app never promises it.) The card names no differences (who joins, who
// isn't carried): the carried mark on rows shows them, Your portion names them.

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
  const CardCarry({required this.carried, required this.status});

  /// The avatar row, always shown: you first, then your carried names in
  /// your order.
  final List<Subject> carried;
  final TomorrowStatus status;

  /// Speak about "you" rather than "them": nobody carried but you.
  bool get aboutYouOnly => carried.every((s) => s.isSelf);
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
  final TomorrowStatus tomorrow;
  if (nextListCovered(list, status, localPrayers)) {
    tomorrow = TomorrowStatus.covered;
  } else if (header != null && prayedWithListToday(header, today)) {
    tomorrow = TomorrowStatus.nextPrayerCarries;
  } else {
    tomorrow = TomorrowStatus.prayToCarry;
  }
  return CardCarry(carried: carriedNames(tree), status: tomorrow);
}
