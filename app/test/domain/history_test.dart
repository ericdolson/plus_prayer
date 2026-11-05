import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/domain/models/local_date.dart';
import 'package:plusprayer/domain/models/prayer.dart';
import 'package:plusprayer/domain/models/prayer_list.dart';
import 'package:plusprayer/domain/models/subject.dart';
import 'package:plusprayer/domain/models/subject_history.dart';
import 'package:plusprayer/domain/rules/history.dart';

const _sunday = 0;
const _monday = 1;

LocalDate _d(int y, int m, int d) => LocalDate(y, m, d);

/// List n dated [first] + (n − 1) days.
ListAppearance _list(int n, {LocalDate? first, bool current = false, int? seal = -1}) {
  final date = (first ?? _d(2026, 9, 1)).addDays(n - 1);
  return ListAppearance(
    listId: 'list-$n',
    listNumber: n,
    listDate: date,
    sealVariant: seal == -1 ? date.weekdayFromSunday : seal,
    prayerCount: 100,
    isCurrent: current,
  );
}

SubjectPrayer _prayer(String id, LocalDate on, {bool note = false}) => SubjectPrayer(
      id: id,
      prayedAt: on.toUtc().add(const Duration(hours: 14)),
      localDate: on,
      listContextNumber: 0,
      hasNote: note,
    );

Subject _subject({DateTime? created, Resolution? resolution, DateTime? resolvedAt, String? parentId}) => Subject(
      id: 's',
      kind: parentId == null ? SubjectKind.soul : SubjectKind.intention,
      parentId: parentId,
      publicName: 'Gary Olson',
      sortOrder: 1,
      createdAt: created ?? DateTime(2026, 9, 1, 12),
      resolution: resolution,
      resolvedAt: resolvedAt,
    );

List<StrandItem> _strandOf(SubjectHistoryView v, PeriodKind kind) => v.periods.firstWhere((p) => p.kind == kind).strand;

String _describe(List<StrandItem> strand) => strand
    .map((i) => switch (i) {
          StrandBead(:final listNumber) => '$listNumber',
          StrandGap() => 'break',
        })
    .join(' ');

void main() {
  group('periodRanges', () {
    test('early in the month, Sunday start: last week is all October, no "Earlier in November"', () {
      // Tue 2026-11-03.
      final r = periodRanges(today: _d(2026, 11, 3), firstDayOfWeek: _sunday, earliest: _d(2026, 9, 1));
      expect(r[0], (kind: PeriodKind.thisWeek, start: _d(2026, 11, 1), end: _d(2026, 11, 3)));
      expect(r[1], (kind: PeriodKind.lastWeek, start: _d(2026, 10, 25), end: _d(2026, 10, 31)));
      expect(r[2], (kind: PeriodKind.month, start: _d(2026, 10, 1), end: _d(2026, 10, 24)));
      expect(r[3], (kind: PeriodKind.month, start: _d(2026, 9, 1), end: _d(2026, 9, 30)));
      expect(r.last, (kind: PeriodKind.month, start: _d(2026, 1, 1), end: _d(2026, 1, 31)));
      expect(r.where((p) => p.kind == PeriodKind.year), isEmpty);
    });

    test('Monday start follows the locale', () {
      final r = periodRanges(today: _d(2026, 11, 3), firstDayOfWeek: _monday, earliest: _d(2026, 9, 1));
      expect(r[0].start, _d(2026, 11, 2));
      expect(r[1], (kind: PeriodKind.lastWeek, start: _d(2026, 10, 26), end: _d(2026, 11, 1)));
      expect(r[2], (kind: PeriodKind.month, start: _d(2026, 10, 1), end: _d(2026, 10, 25)));
    });

    test('mid-month: "Earlier in November" holds only the days not shown above', () {
      // Fri 2026-11-20.
      final r = periodRanges(today: _d(2026, 11, 20), firstDayOfWeek: _sunday, earliest: _d(2026, 9, 1));
      expect(r[0].start, _d(2026, 11, 15));
      expect(r[1].start, _d(2026, 11, 8));
      expect(r[2], (kind: PeriodKind.earlierThisMonth, start: _d(2026, 11, 1), end: _d(2026, 11, 7)));
      expect(r[3], (kind: PeriodKind.month, start: _d(2026, 10, 1), end: _d(2026, 10, 31)));
    });

    test('early January: last week reaches into December; the year row holds the rest of that year', () {
      // Sun 2027-01-03.
      final r = periodRanges(today: _d(2027, 1, 3), firstDayOfWeek: _sunday, earliest: _d(2025, 6, 1));
      expect(r[0], (kind: PeriodKind.thisWeek, start: _d(2027, 1, 3), end: _d(2027, 1, 3)));
      expect(r[1], (kind: PeriodKind.lastWeek, start: _d(2026, 12, 27), end: _d(2027, 1, 2)));
      expect(r[2], (kind: PeriodKind.year, start: _d(2026, 1, 1), end: _d(2026, 12, 26)));
      expect(r[3], (kind: PeriodKind.year, start: _d(2025, 1, 1), end: _d(2025, 12, 31)));
      expect(r.length, 4);
    });
  });

  group('subjectHistoryView', () {
    final today = _d(2026, 11, 3); // Tuesday; Sunday start: this week = Nov 1–3.
    // Lists 1… dated Sep 1…; list 62 = Nov 1, 64 = Nov 3.
    SubjectHistoryView view(List<int> on, {List<SubjectPrayer> prayers = const [], Subject? subject}) =>
        subjectHistoryView(
          subject ?? _subject(),
          SubjectHistory(subjectId: 's', entries: [for (final n in on) _list(n)], prayers: prayers),
          today: today,
          firstDayOfWeek: _sunday,
        );

    test('only this week draws beads; a list missed between two is an unlabeled break', () {
      // This week = Nov 1–3 = lists 62–64; off 63. Last week = lists 55–61.
      final v = view([55, 56, 59, 60, 61, 62, 64]);
      expect(_describe(_strandOf(v, PeriodKind.thisWeek)), '62 break 64');
      final lastWeek = v.periods.firstWhere((p) => p.kind == PeriodKind.lastWeek);
      expect(lastWeek.showsStrand, isFalse);
      expect(lastWeek.listCount, 5);
    });

    test('no break before the first bead this week, even after a gap across weeks', () {
      // Oct 22 = list 52; Nov 2 = list 63: nothing between them is drawn.
      final v = view([51, 52, 63, 64]);
      expect(_describe(_strandOf(v, PeriodKind.thisWeek)), '63 64');
      // Last week had neither lists nor prayers: left out.
      expect(v.periods.map((p) => p.kind), [PeriodKind.thisWeek, PeriodKind.month]);
    });

    test('not on any list this week: text only', () {
      final v = view([], prayers: [_prayer('a', _d(2026, 11, 2))]);
      expect(v.periods.single.kind, PeriodKind.thisWeek);
      expect(v.periods.single.showsStrand, isFalse);
    });

    test('a period holding only the Answered moment stays', () {
      final v = view(
        [62],
        subject: _subject(parentId: 'p', resolution: Resolution.answered, resolvedAt: DateTime(2026, 10, 27, 9)),
      );
      final lastWeek = v.periods.firstWhere((p) => p.kind == PeriodKind.lastWeek);
      expect(lastWeek.answered, isTrue);
      expect(lastWeek.listCount, 0);
      expect(lastWeek.prayerCount, 0);
    });

    test('empty halves: lists without prayers, prayers without lists', () {
      final onlyLists = view([62]);
      expect(onlyLists.periods.single.listCount, 1);
      expect(onlyLists.periods.single.prayerCount, 0);

      final onlyPrayers = view([], prayers: [_prayer('a', _d(2026, 11, 2)), _prayer('b', _d(2026, 11, 3))]);
      expect(onlyPrayers.periods.single.prayerCount, 2);
      expect(onlyPrayers.periods.single.showsStrand, isFalse);
      expect(onlyPrayers.counts.everCarried, isFalse);
    });

    test('year rows count lists', () {
      final v = subjectHistoryView(
        _subject(created: DateTime(2025, 3, 1)),
        SubjectHistory(subjectId: 's', entries: [
          for (var n = 1; n <= 3; n++) _list(n, first: _d(2025, 5, 1)),
          _list(1, first: _d(2026, 11, 3)),
        ]),
        today: today,
        firstDayOfWeek: _sunday,
      );
      final year = v.periods.firstWhere((p) => p.kind == PeriodKind.year);
      expect(year.start, _d(2025, 1, 1));
      expect(year.listCount, 3);
      expect(year.showsStrand, isFalse);
    });

    test('notes, the current list and the Answered moment land on their period', () {
      final v = view(
        [62, 63, 64],
        prayers: [_prayer('a', _d(2026, 11, 2), note: true), _prayer('b', _d(2026, 11, 3)), _prayer('c', _d(2026, 10, 20))],
        subject: _subject(parentId: 'p', resolution: Resolution.answered, resolvedAt: DateTime(2026, 10, 20, 9)),
      );
      final week = v.periods.first;
      expect(week.noteCount, 1);
      expect(week.answered, isFalse);
      final october = v.periods.firstWhere((p) => p.kind == PeriodKind.month);
      expect(october.answered, isTrue);
      expect(v.begun, _d(2026, 9, 1));
      expect(v.counts.heldByYou, 3);
      expect(v.counts.lists, 3);
      expect(v.counts.worldPrayers, 300);
    });

    test('the current list always counts in this week, whatever its date', () {
      // Dated Oct 31 (last week), but current: this week's bead.
      final v = subjectHistoryView(
        _subject(),
        SubjectHistory(subjectId: 's', entries: [_list(60), _list(61, current: true)]),
        today: today,
        firstDayOfWeek: _sunday,
      );
      expect(_describe(_strandOf(v, PeriodKind.thisWeek)), '61');
      expect(v.periods.firstWhere((p) => p.kind == PeriodKind.lastWeek).listCount, 1);
    });

    test('a list dated after today (just flipped) counts in this week', () {
      final v = view([65]); // Nov 4
      expect(v.periods.single.kind, PeriodKind.thisWeek);
    });
  });

  group('stitching', () {
    final today = _d(2026, 11, 3);
    final current = CurrentList(
      id: 'list-64',
      listNumber: 64,
      listDate: today,
      isPublished: false,
      soulCount: 1,
      intentionCount: 0,
      prayerCount: 4321,
    );

    test('the current list is marked, unsealed while being filmed, with its live count', () {
      final h = historyWithCurrentList(
        SubjectHistory(subjectId: 's', entries: [_list(63), _list(64, current: true)]),
        current,
      );
      final bead = h.entries.firstWhere((e) => e.listNumber == 64);
      expect(bead.isCurrent, isTrue);
      expect(bead.sealVariant, isNull);
      expect(bead.prayerCount, 4321);
      expect(h.entries.firstWhere((e) => e.listNumber == 63).isCurrent, isFalse);
      expect(subjectCounts(h).worldPrayers, 100 + 4321);

      final v = subjectHistoryView(_subject(), h, today: today, firstDayOfWeek: _sunday);
      expect(v.periods.first.onCurrentList, isTrue);
      expect((v.periods.first.strand.last as StrandBead).sealVariant, isNull);
    });

    test('local prayers fold in once, and an intention\'s prayer holds its name', () {
      NewPrayer local(String id, List<String> ids) => NewPrayer(
            id: id,
            startedAt: DateTime(2026, 11, 3, 7),
            prayedAt: DateTime(2026, 11, 3, 7, 5),
            durationSeconds: 300,
            localDate: today,
            timezone: 'America/Denver',
            listContextNumber: 64,
            subjectIds: ids,
          );
      final h = SubjectHistory(subjectId: 'dad', prayers: [_prayer('known', today)]);
      final folded = historyWithLocalPrayers(
        h,
        [local('known', ['dad']), local('via-intention', ['dad-1']), local('other', ['mom'])],
        childIds: {'dad-1'},
      );
      expect(folded.prayers.map((p) => p.id), ['known', 'via-intention']);
    });
  });
}
