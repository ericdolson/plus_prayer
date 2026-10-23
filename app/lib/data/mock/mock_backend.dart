// An in-memory stand-in for SQL Connect + the callables + RTDB, applying the
// same rules the server does (via domain/rules). Mock repositories are views
// over it, and MockWriteSender applies queued writes to it. Flip [online] to
// exercise the offline queue.

import 'dart:async';
import 'dart:math' as math;

import '../../domain/models/live.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_list.dart';
import '../../domain/models/reminder.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/user_header.dart';
import '../../domain/rules/carry.dart';
import '../../domain/rules/streak.dart';
import '../../domain/rules/subject_tree.dart';
import '../../domain/rules/validation.dart';
import '../queue/queued_prayer_repository.dart';
import '../queue/write_queue.dart';
import '../repositories/repositories.dart';
import 'mock_seed.dart';

const _subjectCap = 500;

class MockBackend {
  MockBackend({
    MockSeed? seed,
    DateTime Function()? now,
    this.latency = const Duration(milliseconds: 250),
    this.liveDrift = true,
  })  : _now = now ?? DateTime.now,
        _seed = seed ?? MockSeed.standard((now ?? DateTime.now)()) {
    _subjects = [..._seed.subjects];
    _header = _seed.header;
    _reminders = [..._seed.reminders];
    _list = _seed.list;
    _stats = _seed.stats;
  }

  final MockSeed _seed;
  final DateTime Function() _now;

  /// Simulated network latency for reads after writes and for callables.
  final Duration latency;

  /// Nudge the live counts now and then, like `/stats/live` does.
  final bool liveDrift;

  bool online = true;

  late List<Subject> _subjects;
  late UserHeader _header;
  late List<Reminder> _reminders;
  late CurrentList? _list;
  late LiveStats _stats;
  final Set<String> _loggedPrayerIds = {};
  final Map<String, String?> _notes = {};
  PrayerDraft? _draft;
  int _nextId = 1;

  final _subjectsCtl = StreamController<List<Subject>>.broadcast();
  final _headerCtl = StreamController<UserHeader?>.broadcast();
  final _remindersCtl = StreamController<List<Reminder>>.broadcast();
  final _listCtl = StreamController<CurrentList?>.broadcast();
  final _statsCtl = StreamController<LiveStats>.broadcast();
  Timer? _drift;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  UserHeader get header => _header;
  List<Reminder> get reminders => List.unmodifiable(_reminders);
  CurrentList? get currentList => _list;
  Map<String, String?> get notes => Map.unmodifiable(_notes);
  Set<String> get loggedPrayerIds => Set.unmodifiable(_loggedPrayerIds);

  Stream<List<Subject>> watchSubjects() => _withCurrent(_subjects, _subjectsCtl.stream);
  Stream<UserHeader?> watchHeader() => _withCurrent(_header, _headerCtl.stream);
  Stream<List<Reminder>> watchReminders() => _withCurrent(_reminders, _remindersCtl.stream);
  Stream<CurrentList?> watchList() => _withCurrent(_list, _listCtl.stream);

  Stream<LiveStats> watchStats() {
    _startDrift();
    return _withCurrent(_stats, _statsCtl.stream);
  }

  // ---- Callables -----------------------------------------------------------

  /// addSubject: the server's rules — caps, contact check, parent must be an
  /// ACTIVE name of mine, appended at the bottom, auto-carried while the pool
  /// has room.
  Future<AddedSubject> addSubject(NewSubject input) async {
    await Future<void>.delayed(latency);
    if (!online) throw const OfflineError();
    final issue = validatePrinted(input.publicName, input.kind) ?? validateAlias(input.alias);
    if (issue != null) throw SubjectInputError(issue);
    if (_subjects.length >= _subjectCap) throw const SubjectCapError();
    if (input.kind == SubjectKind.intention) {
      final parent = _subjects.where((s) => s.id == input.parentId).firstOrNull;
      if (parent == null || !parent.isName) throw ArgumentError('That name was not found');
    }

    final level = _subjects.where((s) => !s.isSelf && s.parentId == input.parentId);
    final sortOrder = level.fold<int>(0, (m, s) => math.max(m, s.sortOrder)) + 1;
    final alias = input.alias == null ? null : cleanText(input.alias!);
    final draft = Subject(
      id: 'm${_nextId++}',
      kind: input.kind,
      parentId: input.parentId,
      publicName: cleanText(input.publicName),
      alias: (alias?.isEmpty ?? true) ? null : alias,
      sortOrder: sortOrder,
      createdAt: _now(),
      isCarried: true,
    );
    final isCarried = checkPool(SubjectTree.of([..._subjects, draft]), _header, _now()).ok;
    final subject = draft.copyWith(isCarried: isCarried);
    _subjects = [..._subjects, subject];
    _subjectsCtl.add(_subjects);
    return AddedSubject(id: subject.id, isCarried: isCarried, sortOrder: sortOrder);
  }

  /// updateMySettings: only the given fields change.
  Future<void> updateSettings(SettingsChange change) async {
    await Future<void>.delayed(latency);
    if (!online) throw const OfflineError();
    final locale = change.locale;
    _header = _header.copyWith(
      listLiveOptIn: change.listLiveOptIn,
      showNamesInNotifications: change.showNamesInNotifications,
      graceOffersEnabled: change.graceOffersEnabled,
      locale: locale == null ? null : () => locale.code,
    );
    _headerCtl.add(_header);
  }

  /// createReminder / updateReminder: one row per preset slot.
  Future<void> setReminder(ReminderSlot slot, {bool? enabled, ClockTime? localTime}) async {
    await Future<void>.delayed(latency);
    if (!online) throw const OfflineError();
    final existing = _reminders.where((r) => r.slot == slot).firstOrNull;
    if (existing == null) {
      if (localTime == null) throw ArgumentError('A new reminder needs a time');
      _reminders = [
        ..._reminders,
        Reminder(id: 'r${_nextId++}', slot: slot, enabled: enabled ?? true, localTime: localTime),
      ];
    } else {
      _reminders = [
        for (final r in _reminders) r.slot == slot ? r.copyWith(enabled: enabled, localTime: localTime) : r,
      ];
    }
    _remindersCtl.add(_reminders);
  }

  // ---- Writes (from the queue) --------------------------------------------

  /// logPrayer + onPrayerLogged, idempotent by id.
  void applyPrayer(NewPrayer p) {
    if (!_loggedPrayerIds.add(p.id)) return;
    final byId = {for (final s in _subjects) s.id: s};
    final linked = {
      ...p.subjectIds.where(byId.containsKey),
      for (final id in p.subjectIds)
        if (byId[id]?.parentId != null) byId[id]!.parentId!,
    };
    _subjects = [
      for (final s in _subjects)
        if (linked.contains(s.id) && (s.lastPrayed == null || p.localDate.isAfter(s.lastPrayed!)))
          s.copyWith(lastPrayed: p.localDate)
        else
          s,
    ];
    _subjectsCtl.add(_subjects);
    _notes[p.id] = p.note;

    if (p.includesList) {
      _header = afterListPrayer(_header, p.localDate);
      _headerCtl.add(_header);
      final list = _list;
      final countsHere = list != null &&
          p.communityListId == list.id &&
          (list.closesAt == null || p.startedAt.isBefore(list.closesAt!));
      if (countsHere) {
        _list = list.copyWith(prayerCount: list.prayerCount + 1);
        _listCtl.add(_list);
      }
    }
  }

  void applyNote(String prayerId, String? note) {
    if (_loggedPrayerIds.contains(prayerId)) _notes[prayerId] = note;
  }

  // ---- Presence / draft ----------------------------------------------------

  Future<void> writeDraft(PrayerDraft? draft) async => _draft = draft;
  Future<PrayerDraft?> readDraft() async => _draft;

  // ---- Scenario controls (dev tools, tests) -------------------------------

  /// Sets the list's cutoff, as Eric's closeList does (mirrored to RTDB).
  void setClosesAt(DateTime? closesAt) {
    final list = _list;
    if (list == null) return;
    _list = CurrentList(
      id: list.id,
      listNumber: list.listNumber,
      listDate: list.listDate,
      isPublished: list.isPublished,
      soulCount: list.soulCount,
      intentionCount: list.intentionCount,
      prayerCount: list.prayerCount,
      currentFrom: list.currentFrom,
      closesAt: closesAt,
      videoPublishedAt: list.videoPublishedAt,
      videoPath: list.videoPath,
      sealVariant: list.sealVariant,
    );
    _listCtl.add(_list);
  }

  void setStats(LiveStats stats) {
    _stats = stats;
    _statsCtl.add(stats);
  }

  void _startDrift() {
    if (!liveDrift || _drift != null) return;
    final rng = math.Random(7);
    _drift = Timer.periodic(const Duration(seconds: 6), (_) {
      final now = math.max(0, _stats.prayingNow + rng.nextInt(7) - 3);
      setStats(LiveStats(
        prayingNow: now,
        prayedLastHour: _stats.prayedLastHour + rng.nextInt(3),
        prayedToday: _stats.prayedToday + rng.nextInt(3),
        updatedAt: _now(),
      ));
    });
  }

  Stream<T> _withCurrent<T>(T current, Stream<T> changes) async* {
    yield current;
    yield* changes;
  }

  void dispose() {
    _drift?.cancel();
    _subjectsCtl.close();
    _headerCtl.close();
    _remindersCtl.close();
    _listCtl.close();
    _statsCtl.close();
  }
}

/// Applies queued writes to the mock backend; offline → transient.
class MockWriteSender implements WriteSender {
  MockWriteSender(this.backend);

  final MockBackend backend;

  @override
  Future<void> send(PendingWrite write) async {
    await Future<void>.delayed(backend.latency);
    if (!backend.online) throw const TransientWriteError('offline');
    switch (write.op) {
      case WriteOps.logPrayer:
        final p = NewPrayer.fromJson(write.args);
        if (p.durationSeconds < 5 || p.durationSeconds > 14400) {
          throw const PermanentWriteError('invalid-argument', 'A prayer is recorded between 5 seconds and 4 hours');
        }
        backend.applyPrayer(p);
      case WriteOps.updatePrayerNote:
        backend.applyNote(write.args['id'] as String, write.args['note'] as String?);
      default:
        throw PermanentWriteError('unimplemented', write.op);
    }
  }
}

class MockSubjectRepository implements SubjectRepository {
  MockSubjectRepository(this.backend);
  final MockBackend backend;

  @override
  Stream<List<Subject>> watchSubjects() => backend.watchSubjects();

  @override
  Future<AddedSubject> addSubject(NewSubject input) => backend.addSubject(input);
}

class MockListRepository implements ListRepository {
  MockListRepository(this.backend);
  final MockBackend backend;

  @override
  Stream<CurrentList?> watchCurrentList() => backend.watchList();
}

class MockUserRepository implements UserRepository {
  MockUserRepository(this.backend);
  final MockBackend backend;

  @override
  Stream<UserHeader?> watchHeader() => backend.watchHeader();

  @override
  Stream<List<Reminder>> watchReminders() => backend.watchReminders();

  @override
  Future<void> updateSettings(SettingsChange change) => backend.updateSettings(change);

  @override
  Future<void> setReminder(ReminderSlot slot, {bool? enabled, ClockTime? localTime}) =>
      backend.setReminder(slot, enabled: enabled, localTime: localTime);
}

class MockLiveRepository implements LiveRepository {
  MockLiveRepository(this.backend);
  final MockBackend backend;

  @override
  Stream<LiveStats> watchStats() => backend.watchStats();

  @override
  Stream<AppConfig> watchConfig() => Stream.value(AppConfig.defaults);

  @override
  Future<void> writeDraft(PrayerDraft? draft) => backend.writeDraft(draft);

  @override
  Future<PrayerDraft?> readDraft() => backend.readDraft();
}
