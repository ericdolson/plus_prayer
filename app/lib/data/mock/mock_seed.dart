// Mock data shaped exactly like the SQL Connect results. Dates are relative to
// "now" so "Prayed today" / "Last prayed 3 days ago" read naturally whenever
// the app runs. Names are illustrative.
//
// History (detail page): Lists 1–51 closed and sealed (weekday waxes mix in
// every strand), List 52 current. Gaps: Me off Lists 12–13 and 38–40, Dad
// off 47–48 (last week or so), Mom off 31–35. Mom's "A safe delivery for
// Ruth" was answered 16 days ago, on its last list. "Rest for his heart"
// (private) has prayers but no lists; "Our parish" has lists but no prayers.

import '../../domain/models/live.dart';
import '../../domain/models/local_date.dart';
import '../../domain/models/prayer_list.dart';
import '../../domain/models/reminder.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/subject_history.dart';
import '../../domain/models/user_header.dart';

class MockSeed {
  const MockSeed({
    required this.subjects,
    required this.header,
    required this.list,
    required this.stats,
    this.reminders = const [],
    this.myStatus,
    this.pastLists = const [],
    this.onLists = const {},
    this.prayers = const [],
  });

  final List<Subject> subjects;
  final UserHeader header;
  final List<Reminder> reminders;

  /// getMyListStatus for [list].
  final MyListStatus? myStatus;
  final CurrentList? list;
  final LiveStats stats;

  /// Closed lists, any order (`isCurrent` false).
  final List<ListAppearance> pastLists;

  /// Subject id → the list numbers it was printed on (the current list
  /// included).
  final Map<String, List<int>> onLists;

  /// The user's past prayers.
  final List<SeedPrayer> prayers;

  /// A user a week into the reverse trial: 7 of 10 places carried, a 6-day
  /// streak that last counted yesterday, today's list sealed and published.
  factory MockSeed.standard(DateTime now) {
    final today = LocalDate.of(now);
    LocalDate daysAgo(int n) => today.addDays(-n);
    DateTime createdDaysAgo(int n) => now.subtract(Duration(days: n));

    Subject name(
      String id,
      String publicName, {
      required int order,
      String? alias,
      bool carried = true,
      bool self = false,
      int? lastPrayedDaysAgo,
      int? tone,
      required int createdAgo,
    }) =>
        Subject(
          id: id,
          kind: SubjectKind.soul,
          publicName: publicName,
          alias: alias,
          isSelf: self,
          isCarried: carried,
          sortOrder: order,
          avatarTone: tone,
          createdAt: createdDaysAgo(createdAgo),
          lastPrayed: lastPrayedDaysAgo == null ? null : daysAgo(lastPrayedDaysAgo),
        );

    Subject intention(
      String id,
      String parentId,
      String text, {
      required int order,
      bool carried = true,
      int? lastPrayedDaysAgo,
      DateTime? answeredAt,
      required int createdAgo,
    }) =>
        Subject(
          id: id,
          kind: SubjectKind.intention,
          parentId: parentId,
          publicName: text,
          isCarried: carried,
          sortOrder: order,
          createdAt: createdDaysAgo(createdAgo),
          resolution: answeredAt == null ? null : Resolution.answered,
          resolvedAt: answeredAt,
          lastPrayed: lastPrayedDaysAgo == null ? null : daysAgo(lastPrayedDaysAgo),
        );

    final subjects = [
      name('self', 'Eric Olson', alias: 'Me', self: true, order: 0, lastPrayedDaysAgo: 1, createdAgo: 52),
      intention('self-1', 'self', 'Patience with the new job', order: 1, lastPrayedDaysAgo: 3, createdAgo: 35),
      // Short mock ids collide in the tone hash (real ids are UUIDs); a few
      // tones are set as if the user picked them, so Home shows a real mix.
      name('dad', 'Gary Olson', alias: 'Dad', order: 1, lastPrayedDaysAgo: 0, tone: 0, createdAgo: 45),
      intention('dad-1', 'dad', 'Healing after his surgery', order: 1, lastPrayedDaysAgo: 0, createdAgo: 40),
      intention('dad-2', 'dad', 'Rest for his heart', order: 2, carried: false, lastPrayedDaysAgo: 4, createdAgo: 25),
      name('mom', 'Margaret Olson', alias: 'Mom', order: 2, lastPrayedDaysAgo: 2, createdAgo: 40),
      intention(
        'mom-1',
        'mom',
        'A safe delivery for Ruth',
        order: 1,
        lastPrayedDaysAgo: 2,
        answeredAt: now.subtract(const Duration(days: 16)),
        createdAgo: 39,
      ),
      name('daniel', 'Daniel Kim', order: 3, lastPrayedDaysAgo: 8, createdAgo: 30),
      name('parish', 'Our parish', order: 4, tone: 13, createdAgo: 15),
      name('ukraine', 'Ukraine', order: 5, lastPrayedDaysAgo: 0, tone: 14, createdAgo: 2),
      name('bea', 'Beatrice Moreno', alias: 'Aunt Bea', order: 6, carried: false, lastPrayedDaysAgo: 1, createdAgo: 25),
    ];

    final header = UserHeader(
      id: 'mock-user',
      displayName: 'Eric Olson',
      selfSubjectId: 'self',
      currentStreak: 6,
      bestStreak: 11,
      lastListLocalDate: daysAgo(1),
      graceDays: 1,
      includeLimit: 10,
      trialStartedAt: now.subtract(const Duration(days: 5)),
      entitlementExpiresAt: now.add(const Duration(days: 9)),
    );

    final list = CurrentList(
      id: 'list-52',
      listNumber: 52,
      listDate: today,
      isPublished: true,
      soulCount: 4345,
      intentionCount: 1212,
      prayerCount: 3880,
      currentFrom: now.subtract(const Duration(hours: 3)),
      sealVariant: today.weekdayFromSunday,
      videoPublishedAt: now.subtract(const Duration(hours: 1)),
      videoPath: 'videos/list-52.mp4',
    );

    const stats = LiveStats(prayingNow: 213, prayedLastHour: 640, prayedToday: 4113);

    // Default: Morning on (schema-brief). Preset times are an open question
    // (notifications.md); these are placeholders.
    const reminders = [
      Reminder(id: 'r-morning', slot: ReminderSlot.morning, enabled: true, localTime: ClockTime(7, 0)),
      Reminder(id: 'r-midday', slot: ReminderSlot.midday, enabled: false, localTime: ClockTime(12, 0)),
      Reminder(id: 'r-evening', slot: ReminderSlot.evening, enabled: false, localTime: ClockTime(20, 0)),
    ];

    // History. List n is dated (52 − n) days ago, sealed in its weekday's wax.
    const current = 52;
    LocalDate listDate(int n) => daysAgo(current - n);
    final pastLists = [
      for (var n = 1; n < current; n++)
        ListAppearance(
          listId: 'list-$n',
          listNumber: n,
          listDate: listDate(n),
          sealVariant: listDate(n).weekdayFromSunday,
          prayerCount: 300 + n * 70 + (n * 37) % 113,
        ),
    ];
    List<int> span(int from, int to, [Set<int> except = const {}]) => [
          for (var n = from; n <= to; n++)
            if (!except.contains(n)) n
        ];
    const meOff = {12, 13, 38, 39, 40};
    const dadOff = {47, 48};
    final onLists = {
      'self': span(1, current, meOff),
      'self-1': span(20, current, meOff),
      'dad': span(8, current, dadOff),
      'dad-1': span(15, current, dadOff),
      'mom': span(13, current, {31, 32, 33, 34, 35}),
      // Answered on List 36's day: never printed again.
      'mom-1': [...span(13, 30), 36],
      'daniel': span(25, current),
      'parish': span(40, current),
      // Uncarried since List 52 was assembled.
      'bea': span(30, current),
    };

    // Days ago each subject was held (its latest = `lastPrayed` above). One
    // prayer per day holds everything held that day.
    final heldOn = <String, List<int>>{
      'self': [1, 2, 3, 5, 6, 7, 8, 11, 12, 13, 15, 16, 17, 19, 20, 21, 23, 24, 26, 27, 28, 30, 33, 35, 40, 44, 48],
      'self-1': [3, 5, 8, 12, 15, 20, 26, 33],
      'dad': [0, 1, 2, 3, 5, 6, 8, 9, 10, 12, 13, 15, 16, 19, 20, 23, 24, 26, 27, 30, 33, 34, 37, 40, 43],
      'dad-1': [0, 2, 5, 9, 13, 20, 27, 34],
      'dad-2': [4, 11, 18],
      'mom': [2, 3, 6, 10, 13, 16, 17, 18, 19, 24, 30, 36],
      'mom-1': [2, 16, 17, 18, 19, 24, 30],
      'daniel': [8, 15, 22, 29],
      'ukraine': [0],
      'bea': [1, 7, 14, 21],
    };
    const notedDays = {0, 5, 16, 30};
    final parents = {for (final s in subjects) s.id: s.parentId};
    final days = {for (final d in heldOn.values) ...d}.toList()..sort();
    final midnight = DateTime(now.year, now.month, now.day);
    final prayers = [
      for (final d in days)
        SeedPrayer(
          id: 'seed-prayer-$d',
          // 7:30 most days; today, halfway through the morning so far.
          prayedAt: d == 0
              ? midnight.add(now.difference(midnight) ~/ 2)
              : DateTime(now.year, now.month, now.day - d, 7, 30),
          localDate: daysAgo(d),
          listContextNumber: current - d,
          subjectIds: {
            for (final MapEntry(:key, :value) in heldOn.entries)
              if (value.contains(d)) ...[key, if (parents[key] case final p?) p],
          },
          note: notedDays.contains(d) ? 'A quiet morning.' : null,
        ),
    ];

    // Prayed with List 51 yesterday, so these were printed on List 52. Ukraine
    // was added since ("joins you on List 53").
    ListEntry printed(String id) {
      final s = subjects.firstWhere((s) => s.id == id);
      return ListEntry(subjectId: id, publicName: s.publicName, isName: s.isName, isSelf: s.isSelf);
    }

    final myStatus = MyListStatus(
      listId: list.id,
      entries: [
        for (final MapEntry(:key, :value) in onLists.entries)
          if (value.contains(current)) printed(key)
      ],
    );

    return MockSeed(
      subjects: subjects,
      header: header,
      list: list,
      stats: stats,
      reminders: reminders,
      myStatus: myStatus,
      pastLists: pastLists,
      onLists: onLists,
      prayers: prayers,
    );
  }
}

/// A past prayer in the mock store. [subjectIds] are the LINKED ids: held
/// items plus each held intention's name, as logPrayer writes them.
class SeedPrayer {
  const SeedPrayer({
    required this.id,
    required this.prayedAt,
    required this.localDate,
    required this.listContextNumber,
    required this.subjectIds,
    this.note,
  });

  final String id;
  final DateTime prayedAt;
  final LocalDate localDate;
  final int listContextNumber;
  final Set<String> subjectIds;
  final String? note;

  SeedPrayer withNote(String? note) => SeedPrayer(
        id: id,
        prayedAt: prayedAt,
        localDate: localDate,
        listContextNumber: listContextNumber,
        subjectIds: subjectIds,
        note: note,
      );
}
