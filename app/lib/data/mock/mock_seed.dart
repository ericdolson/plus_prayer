// Mock data shaped exactly like the SQL Connect results. Dates are relative to
// "now" so "Prayed today" / "Last prayed 3 days ago" read naturally whenever
// the app runs. Names are illustrative.

import '../../domain/models/live.dart';
import '../../domain/models/local_date.dart';
import '../../domain/models/prayer_list.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/user_header.dart';

class MockSeed {
  const MockSeed({required this.subjects, required this.header, required this.list, required this.stats});

  final List<Subject> subjects;
  final UserHeader header;
  final CurrentList? list;
  final LiveStats stats;

  /// A user a week into the reverse trial: 7 of 10 places carried, a 6-day
  /// streak that last counted yesterday, today's list sealed and published.
  factory MockSeed.standard(DateTime now) {
    final today = LocalDate.of(now);
    LocalDate daysAgo(int n) => today.addDays(-n);
    final created = now.subtract(const Duration(days: 30));

    Subject name(
      String id,
      String publicName, {
      required int order,
      String? alias,
      bool carried = true,
      bool self = false,
      int? lastPrayedDaysAgo,
      int? tone,
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
          createdAt: created,
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
    }) =>
        Subject(
          id: id,
          kind: SubjectKind.intention,
          parentId: parentId,
          publicName: text,
          isCarried: carried,
          sortOrder: order,
          createdAt: created,
          resolution: answeredAt == null ? null : Resolution.answered,
          resolvedAt: answeredAt,
          lastPrayed: lastPrayedDaysAgo == null ? null : daysAgo(lastPrayedDaysAgo),
        );

    final subjects = [
      name('self', 'Jordan Ellis', alias: 'Me', self: true, order: 0, lastPrayedDaysAgo: 1),
      intention('self-1', 'self', 'Patience with the new job', order: 1, lastPrayedDaysAgo: 3),
      name('dad', 'Gary Olson', alias: 'Dad', order: 1, lastPrayedDaysAgo: 0),
      intention('dad-1', 'dad', 'Healing after his surgery', order: 1, lastPrayedDaysAgo: 0),
      intention('dad-2', 'dad', 'Rest for his heart', order: 2, carried: false),
      name('mom', 'Margaret Olson', alias: 'Mom', order: 2, lastPrayedDaysAgo: 2),
      intention(
        'mom-1',
        'mom',
        'A safe delivery for Ruth',
        order: 1,
        lastPrayedDaysAgo: 2,
        answeredAt: now.subtract(const Duration(days: 16)),
      ),
      name('daniel', 'Daniel Kim', order: 3, lastPrayedDaysAgo: 8),
      name('parish', 'Our parish', order: 4),
      name('ukraine', 'Ukraine', order: 5, lastPrayedDaysAgo: 0),
      name('bea', 'Beatrice Moreno', alias: 'Aunt Bea', order: 6, carried: false, lastPrayedDaysAgo: 1),
    ];

    final header = UserHeader(
      id: 'mock-user',
      displayName: 'Jordan Ellis',
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

    return MockSeed(subjects: subjects, header: header, list: list, stats: stats);
  }
}
