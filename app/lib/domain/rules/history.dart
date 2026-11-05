// The detail page's history (detail-page.md "History",
// stats-history.md): getSubjectDetail's entries and prayers bucketed into
// period rows, newest first.
//
// - Periods: "This week" (from the locale's week start to today), "Last
//   week", "Earlier in {current month}" (only days of this month not already
//   shown; skipped if none), one row per earlier month of this year, one row
//   per earlier year. Then "Begun · {date}" = when the subject was created.
// - One bead strand, for "This week" only (simplified 2026-11-03): a bead per
//   list this week, in that list's wax. Missed lists between two of them are
//   an unlabeled break; none before the first bead or after the last. Every
//   older period is text: counts only, no gaps.
// - Empty halves are left out: lists but no prayers → only "On N lists";
//   prayers but no lists → only "You prayed N times"; neither → the row is
//   left out, unless it holds the Answered moment (then just the hint).
// - The current list always counts in This week, whatever its date.
// - Hints: notes in the period ("✎ 2") and the Answered moment (an
//   intention's own page; names are never answered).
// - Counts: "Held by you" = the user's prayers that held it (tier 1, raw);
//   "Carried by the world" = SUM(prayerCount) over the lists it was on
//   (tier 3), the current list's count live.

import '../models/local_date.dart';
import '../models/prayer.dart';
import '../models/prayer_list.dart';
import '../models/subject.dart';
import '../models/subject_history.dart';

/// Folds this device's prayers the server may not reflect yet into
/// [history], as Home does for `lastPrayed`. A prayer holding one of
/// [childIds] (the name's intentions) holds the name too, as on the server.
/// Idempotent: a prayer the server already returned is skipped by id.
SubjectHistory historyWithLocalPrayers(
  SubjectHistory history,
  List<NewPrayer> local, {
  Set<String> childIds = const {},
}) {
  if (local.isEmpty) return history;
  final known = {for (final p in history.prayers) p.id};
  final added = [
    for (final p in local)
      if (!known.contains(p.id) &&
          (p.subjectIds.contains(history.subjectId) || p.subjectIds.any(childIds.contains)))
        SubjectPrayer(
          id: p.id,
          prayedAt: p.prayedAt,
          localDate: p.localDate,
          listContextNumber: p.listContextNumber,
          hasNote: p.note?.trim().isNotEmpty ?? false,
        ),
  ];
  return added.isEmpty ? history : history.copyWith(prayers: [...history.prayers, ...added]);
}

/// Stitches the live current list in (OPERATIONS.md world-count contract):
/// its entry is marked current and takes the live seal (unsealed until the
/// video is published) and the live prayer count.
SubjectHistory historyWithCurrentList(SubjectHistory history, CurrentList? list) {
  if (list == null) return history;
  return history.copyWith(entries: [
    for (final e in history.entries)
      e.listId == list.id
          ? e.copyWith(
              isCurrent: true,
              sealVariant: list.sealVariant,
              clearSeal: list.sealVariant == null,
              prayerCount: list.prayerCount,
            )
          : e.copyWith(isCurrent: false),
  ]);
}

/// The two counts under the title.
class SubjectCounts {
  const SubjectCounts({required this.heldByYou, required this.worldPrayers, required this.lists});

  /// "Held by you · N prayers" (always shown).
  final int heldByYou;

  /// "Carried by the world · N prayers · N lists": never summed across
  /// subjects into a headline.
  final int worldPrayers;
  final int lists;

  /// The world line shows only once ever carried (never "0 lists").
  bool get everCarried => lists > 0;
}

SubjectCounts subjectCounts(SubjectHistory history) => SubjectCounts(
      heldByYou: history.prayers.length,
      worldPrayers: history.entries.fold(0, (sum, e) => sum + e.prayerCount),
      lists: history.entries.length,
    );

enum PeriodKind { thisWeek, lastWeek, earlierThisMonth, month, year }

/// One piece of a period's strand.
sealed class StrandItem {
  const StrandItem();
}

/// A list the item was on.
class StrandBead extends StrandItem {
  const StrandBead({required this.listNumber, this.sealVariant, this.isCurrent = false});

  final int listNumber;

  /// Null = the current list while unsealed: the neutral `unsealed` color.
  final int? sealVariant;
  final bool isCurrent;
}

/// A quiet break in the thread: lists missed between two beads this week.
/// No label.
class StrandGap extends StrandItem {
  const StrandGap();
}

class HistoryPeriod {
  const HistoryPeriod({
    required this.kind,
    required this.start,
    required this.end,
    required this.strand,
    required this.listCount,
    required this.onCurrentList,
    required this.prayerCount,
    required this.noteCount,
    required this.answered,
  });

  final PeriodKind kind;

  /// Inclusive local dates; [start] names a month or year row.
  final LocalDate start;
  final LocalDate end;

  /// Oldest → newest. This week only; empty on every other row.
  final List<StrandItem> strand;

  /// "On N lists" (+ "· current").
  final int listCount;
  final bool onCurrentList;

  /// "You prayed N times".
  final int prayerCount;

  /// The "✎ N" hint.
  final int noteCount;

  /// The "Answered" hint: the item was answered in this period.
  final bool answered;

  bool get showsStrand => strand.isNotEmpty;
}

class SubjectHistoryView {
  const SubjectHistoryView({required this.counts, required this.periods, required this.begun});

  final SubjectCounts counts;

  /// Newest first; empty rows left out.
  final List<HistoryPeriod> periods;

  /// "Begun · {date}": the day the subject was created.
  final LocalDate begun;
}

/// Buckets [history] into period rows. [firstDayOfWeek]: 0 = Sunday … 6 =
/// Saturday, from the device locale.
SubjectHistoryView subjectHistoryView(
  Subject subject,
  SubjectHistory history, {
  required LocalDate today,
  required int firstDayOfWeek,
}) {
  final begun = LocalDate.of(subject.createdAt.toLocal());
  final answeredOn = subject.resolution == Resolution.answered && subject.resolvedAt != null
      ? LocalDate.of(subject.resolvedAt!.toLocal())
      : null;

  var earliest = begun;
  for (final d in [...history.entries.map((e) => e.listDate), ...history.prayers.map((p) => p.localDate)]) {
    if (d.isBefore(earliest)) earliest = d;
  }
  final ranges = periodRanges(today: today, firstDayOfWeek: firstDayOfWeek, earliest: earliest);

  int indexOf(LocalDate d) {
    // A list dated after today (just flipped) belongs to this week.
    if (d.isAfter(today)) return 0;
    for (var i = 0; i < ranges.length; i++) {
      if (!d.isBefore(ranges[i].start)) return i;
    }
    return ranges.length - 1;
  }

  final strands = List.generate(ranges.length, (_) => <StrandItem>[]);
  final lists = List.filled(ranges.length, 0);
  final current = List.filled(ranges.length, false);
  final prayed = List.filled(ranges.length, 0);
  final notes = List.filled(ranges.length, 0);

  final entries = [...history.entries]..sort((a, b) => a.listNumber.compareTo(b.listNumber));
  int? previousThisWeek;
  for (final e in entries) {
    // The current list always counts in This week, whatever its date (a
    // rare eighth bead after a flip is fine).
    final i = e.isCurrent ? 0 : indexOf(e.listDate);
    lists[i]++;
    if (e.isCurrent) current[i] = true;
    if (ranges[i].kind == PeriodKind.thisWeek) {
      final previous = previousThisWeek;
      if (previous != null && e.listNumber - previous > 1) strands[i].add(const StrandGap());
      strands[i].add(StrandBead(listNumber: e.listNumber, sealVariant: e.sealVariant, isCurrent: e.isCurrent));
      previousThisWeek = e.listNumber;
    }
  }
  for (final p in history.prayers) {
    final i = indexOf(p.localDate);
    prayed[i]++;
    if (p.hasNote) notes[i]++;
  }

  bool answeredIn(PeriodRange r) => answeredOn != null && !answeredOn.isBefore(r.start) && !answeredOn.isAfter(r.end);
  final periods = [
    for (var i = 0; i < ranges.length; i++)
      if (lists[i] > 0 || prayed[i] > 0 || answeredIn(ranges[i]))
        HistoryPeriod(
          kind: ranges[i].kind,
          start: ranges[i].start,
          end: ranges[i].end,
          strand: List.unmodifiable(strands[i]),
          listCount: lists[i],
          onCurrentList: current[i],
          prayerCount: prayed[i],
          noteCount: notes[i],
          answered: answeredIn(ranges[i]),
        ),
  ];
  return SubjectHistoryView(counts: subjectCounts(history), periods: periods, begun: begun);
}

typedef PeriodRange = ({PeriodKind kind, LocalDate start, LocalDate end});

/// The period rows' date ranges, newest first, back to [earliest]'s year.
/// Contiguous and non-overlapping: each row holds only days not already
/// shown above it.
List<PeriodRange> periodRanges({required LocalDate today, required int firstDayOfWeek, required LocalDate earliest}) {
  final weekStart = today.addDays(-((today.weekdayFromSunday - firstDayOfWeek) % 7));
  final lastWeekStart = weekStart.addDays(-7);
  final ranges = <PeriodRange>[
    (kind: PeriodKind.thisWeek, start: weekStart, end: today),
    (kind: PeriodKind.lastWeek, start: lastWeekStart, end: weekStart.addDays(-1)),
  ];
  var shownFrom = lastWeekStart;
  final monthStart = LocalDate(today.year, today.month, 1);
  if (monthStart.isBefore(shownFrom)) {
    ranges.add((kind: PeriodKind.earlierThisMonth, start: monthStart, end: shownFrom.addDays(-1)));
    shownFrom = monthStart;
  }
  LocalDate earlier(LocalDate a, LocalDate b) => a.isBefore(b) ? a : b;
  for (var m = today.month - 1; m >= 1; m--) {
    final start = LocalDate(today.year, m, 1);
    final end = earlier(LocalDate(today.year, m + 1, 1).addDays(-1), shownFrom.addDays(-1));
    if (!end.isBefore(start)) ranges.add((kind: PeriodKind.month, start: start, end: end));
  }
  for (var y = today.year - 1; y >= earliest.year; y--) {
    final start = LocalDate(y, 1, 1);
    final end = earlier(LocalDate(y, 12, 31), shownFrom.addDays(-1));
    if (!end.isBefore(start)) ranges.add((kind: PeriodKind.year, start: start, end: end));
  }
  return ranges;
}
