// Riverpod wiring. Repositories are overridden per environment
// (app/environment.dart) and in tests; everything else derives from them with
// the pure rules in domain/rules.

import 'dart:async';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/queue/write_queue.dart';
import '../data/repositories/repositories.dart';
import '../domain/models/live.dart';
import '../domain/models/local_date.dart';
import '../domain/models/prayer.dart';
import '../domain/models/prayer_list.dart';
import '../domain/models/subject.dart';
import '../domain/models/user_header.dart';
import '../domain/rules/local_prayers.dart';
import '../domain/rules/subject_tree.dart';

// ---- Environment (overridden) ----------------------------------------------

Never _override(String name) => throw UnimplementedError('$name must be overridden by the Environment');

final subjectRepositoryProvider = Provider<SubjectRepository>((_) => _override('subjectRepositoryProvider'));
final listRepositoryProvider = Provider<ListRepository>((_) => _override('listRepositoryProvider'));
final userRepositoryProvider = Provider<UserRepository>((_) => _override('userRepositoryProvider'));
final prayerRepositoryProvider = Provider<PrayerRepository>((_) => _override('prayerRepositoryProvider'));
final liveRepositoryProvider = Provider<LiveRepository>((_) => _override('liveRepositoryProvider'));
final writeQueueProvider = Provider<WriteQueue>((_) => _override('writeQueueProvider'));

// ---- Device ------------------------------------------------------------------

/// The clock. Tests override it.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Ticks every 15 s so day boundaries and the closing banner stay current.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(seconds: 15), (_) => clock());
});

/// The device's local calendar day.
final todayProvider = Provider<LocalDate>((ref) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  return LocalDate.of(now);
});

/// IANA zone of the device (`Prayer.timezone`, `User.timezone`).
final timezoneProvider = FutureProvider<String>((_) async {
  try {
    return await FlutterTimezone.getLocalTimezone();
  } catch (_) {
    return 'UTC';
  }
});

/// Client-generated ids, in SQL Connect's form (32 hex digits, no dashes).
final idGeneratorProvider = Provider<String Function()>((_) {
  const uuid = Uuid();
  return () => uuid.v4().replaceAll('-', '');
});

// ---- Data ------------------------------------------------------------------

final _serverSubjectsProvider = StreamProvider<List<Subject>>(
  (ref) => ref.watch(subjectRepositoryProvider).watchSubjects(),
);

final localPrayersProvider = StreamProvider<List<NewPrayer>>(
  (ref) => ref.watch(prayerRepositoryProvider).watchLocalPrayers(),
);

/// Subjects with this device's not-yet-reflected prayers folded in.
final subjectsProvider = Provider<AsyncValue<List<Subject>>>((ref) {
  final local = ref.watch(localPrayersProvider).value ?? const [];
  return ref.watch(_serverSubjectsProvider).whenData((s) => subjectsWithLocalPrayers(s, local));
});

final subjectTreeProvider = Provider<AsyncValue<SubjectTree>>(
  (ref) => ref.watch(subjectsProvider).whenData(SubjectTree.of),
);

final _serverHeaderProvider = StreamProvider<UserHeader?>(
  (ref) => ref.watch(userRepositoryProvider).watchHeader(),
);

/// The header with local list prayers applied (streak, "prayed today").
final headerProvider = Provider<AsyncValue<UserHeader?>>((ref) {
  final local = ref.watch(localPrayersProvider).value ?? const [];
  return ref.watch(_serverHeaderProvider).whenData((h) => h == null ? null : headerWithLocalPrayers(h, local));
});

final currentListProvider = StreamProvider<CurrentList?>(
  (ref) => ref.watch(listRepositoryProvider).watchCurrentList(),
);

final liveStatsProvider = StreamProvider<LiveStats>(
  (ref) => ref.watch(liveRepositoryProvider).watchStats(),
);

final _configStreamProvider = StreamProvider<AppConfig>(
  (ref) => ref.watch(liveRepositoryProvider).watchConfig(),
);

/// `/config`, falling back to the compiled-in defaults until it arrives.
final configProvider = Provider<AppConfig>(
  (ref) => ref.watch(_configStreamProvider).value ?? AppConfig.defaults,
);

final queueStateProvider = StreamProvider<QueueState>((ref) => ref.watch(writeQueueProvider).watch());
