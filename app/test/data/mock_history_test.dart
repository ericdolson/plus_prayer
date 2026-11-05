import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/data/mock/mock_backend.dart';
import 'package:plusprayer/data/repositories/repositories.dart';
import 'package:plusprayer/domain/models/local_date.dart';
import 'package:plusprayer/domain/models/prayer.dart';
import 'package:plusprayer/domain/models/subject_history.dart';
import 'package:plusprayer/domain/rules/history.dart';

import '../helpers.dart';

void main() {
  late MockBackend backend;

  setUp(() => backend = MockBackend(now: () => testNow, latency: Duration.zero, liveDrift: false));
  tearDown(() => backend.dispose());

  Future<SubjectHistory> historyOf(String id) async => (await backend.watchHistory(id).first)!;

  List<int> numbers(SubjectHistory h) => [for (final e in h.entries) e.listNumber]..sort();

  test('Dad: printed since List 8, off 47–48, on the current list; weekday waxes mix', () async {
    final h = await historyOf('dad');
    final n = numbers(h);
    expect(n.first, 8);
    expect(n.last, 52);
    expect(n, isNot(contains(47)));
    expect(n, isNot(contains(48)));
    expect(h.entries.where((e) => e.isCurrent).single.listNumber, 52);
    expect({for (final e in h.entries) e.sealVariant}, {0, 1, 2, 3, 4, 5, 6});
  });

  test('the answered intention stops at its last list; the private one has prayers but no lists', () async {
    final answered = await historyOf('mom-1');
    expect(numbers(answered).last, 36);
    final private = await historyOf('dad-2');
    expect(private.entries, isEmpty);
    expect(private.prayers, isNotEmpty);
    final parish = await historyOf('parish');
    expect(parish.prayers, isEmpty);
    expect(parish.entries, isNotEmpty);
  });

  test('an intention\'s prayer is linked to its name', () async {
    final dad = await historyOf('dad');
    final dad2 = await historyOf('dad-2');
    final dadIds = {for (final p in dad.prayers) p.id};
    expect(dad2.prayers.every((p) => dadIds.contains(p.id)), isTrue);
  });

  test('a logged prayer and its note show up in the history', () async {
    final updates = backend.watchHistory('dad');
    final seen = <SubjectHistory?>[];
    final sub = updates.listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    final before = seen.last!.prayers.length;
    backend.applyPrayer(NewPrayer(
      id: 'p1',
      startedAt: testNow,
      prayedAt: testNow.add(const Duration(minutes: 3)),
      durationSeconds: 180,
      localDate: LocalDate.of(testNow),
      timezone: 'America/Denver',
      listContextNumber: 52,
      subjectIds: const ['dad-1'],
    ));
    backend.applyNote('p1', 'Thank you');
    await Future<void>.delayed(Duration.zero);
    expect(seen.last!.prayers.length, before + 1);
    expect(seen.last!.prayers.firstWhere((p) => p.id == 'p1').hasNote, isTrue);
    await sub.cancel();
  });

  test('flip: List 52 closes; prayed with it → the carried are on unsealed List 53; sealing gives its wax',
      () async {
    backend.applyPrayer(NewPrayer(
      id: 'list-prayer',
      startedAt: testNow,
      prayedAt: testNow.add(const Duration(minutes: 1)),
      durationSeconds: 60,
      localDate: LocalDate.of(testNow),
      timezone: 'America/Denver',
      listContextNumber: 52,
      communityListId: 'list-52',
      subjectIds: const [],
    ));
    backend.flipList();
    var dad = await historyOf('dad');
    final current = dad.entries.singleWhere((e) => e.isCurrent);
    expect(current.listNumber, 53);
    expect(current.sealVariant, isNull);
    expect(dad.entries.singleWhere((e) => e.listNumber == 52).isCurrent, isFalse);
    // Carried intention prints with its name; private and uncarried don't.
    expect(numbers(await historyOf('dad-1')), contains(53));
    expect(numbers(await historyOf('dad-2')), isEmpty);
    expect(numbers(await historyOf('bea')), isNot(contains(53)));

    backend.setSealed(true);
    dad = await historyOf('dad');
    expect(dad.entries.singleWhere((e) => e.isCurrent).sealVariant, LocalDate.of(testNow).addDays(1).weekdayFromSunday);
  });

  test('on a Saturday, Me has a full week of seven waxes; Dad has a break; the current bead can be unsealed',
      () async {
    // Saturday 2026-10-24: with a Sunday start, this week = Lists 46–52.
    final saturday = DateTime(2026, 10, 24, 9);
    final b = MockBackend(now: () => saturday, latency: Duration.zero, liveDrift: false);
    addTearDown(b.dispose);
    Future<SubjectHistoryView> view(String id) async => subjectHistoryView(
          b.subjects.firstWhere((s) => s.id == id),
          (await b.watchHistory(id).first)!,
          today: LocalDate.of(saturday),
          firstDayOfWeek: 0,
        );
    final me = (await view('self')).periods.first;
    expect([for (final i in me.strand) (i as StrandBead).sealVariant], [0, 1, 2, 3, 4, 5, 6]);

    final dad = (await view('dad')).periods.first;
    expect(dad.strand.whereType<StrandGap>().length, 1);

    b.setSealed(false);
    final unsealed = (await view('self')).periods.first;
    expect((unsealed.strand.last as StrandBead).sealVariant, isNull);
  });

  test('self name: once printed, one change per 7 days, with the next date', () async {
    await backend.setSelfName('Eric D. Olson');
    expect(backend.subjects.firstWhere((s) => s.isSelf).publicName, 'Eric D. Olson');
    await expectLater(
      backend.setSelfName('Eric Olson'),
      throwsA(isA<SelfNameTooSoonError>()
          .having((e) => e.nextAvailable, 'nextAvailable', testNow.add(const Duration(days: 7)))),
    );
  });

  test('archive takes a name\'s intentions; release and answered on an intention', () async {
    await backend.markAnswered('dad-1');
    expect(backend.subjects.firstWhere((s) => s.id == 'dad-1').isResolved, isTrue);
    await backend.release('self-1');
    expect(backend.subjects.any((s) => s.id == 'self-1'), isFalse);
    await backend.archive('dad');
    expect(backend.subjects.where((s) => s.id == 'dad' || s.parentId == 'dad'), isEmpty);
  });
}
