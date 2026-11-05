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
import '../../domain/models/subject_history.dart';
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
    _myStatus = _seed.myStatus ?? (_seed.list == null ? null : MyListStatus(listId: _seed.list!.id));
    _stats = _seed.stats;
    _closedLists = {for (final l in _seed.pastLists) l.listNumber: l};
    _onLists = {for (final MapEntry(:key, :value) in _seed.onLists.entries) key: {...value}};
    _prayers = [..._seed.prayers];
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
  late MyListStatus? _myStatus;
  late LiveStats _stats;

  /// History: closed lists by number, subject id → list numbers it was
  /// printed on (the current one included), and the user's prayers.
  late Map<int, ListAppearance> _closedLists;
  late Map<String, Set<int>> _onLists;
  late List<SeedPrayer> _prayers;
  final Set<String> _loggedPrayerIds = {};

  /// `User.selfNameChangedAt`.
  DateTime? _selfNameChangedAt;
  final Map<String, String?> _notes = {};
  PrayerDraft? _draft;
  int _nextId = 1;

  final _subjectsCtl = StreamController<List<Subject>>.broadcast();
  final _headerCtl = StreamController<UserHeader?>.broadcast();
  final _remindersCtl = StreamController<List<Reminder>>.broadcast();
  final _listCtl = StreamController<CurrentList?>.broadcast();
  final _myStatusCtl = StreamController<MyListStatus?>.broadcast();
  final _statsCtl = StreamController<LiveStats>.broadcast();
  final _historyCtl = StreamController<void>.broadcast();
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
  Stream<MyListStatus?> watchMyStatus() => _withCurrent(_myStatus, _myStatusCtl.stream);

  /// getSubjectDetail's history half, re-read after every write.
  Stream<SubjectHistory?> watchHistory(String subjectId) async* {
    yield _historyOf(subjectId);
    yield* _historyCtl.stream.map((_) => _historyOf(subjectId));
  }

  SubjectHistory? _historyOf(String id) {
    if (!_subjects.any((s) => s.id == id)) return null;
    final list = _list;
    return SubjectHistory(
      subjectId: id,
      entries: [
        for (final n in _onLists[id] ?? const <int>{})
          if (list != null && n == list.listNumber)
            ListAppearance(
              listId: list.id,
              listNumber: n,
              listDate: list.listDate,
              sealVariant: list.sealVariant,
              prayerCount: list.prayerCount,
              isCurrent: true,
            )
          else if (_closedLists[n] case final closed?)
            closed,
      ],
      prayers: [
        for (final p in _prayers)
          if (p.subjectIds.contains(id))
            SubjectPrayer(
              id: p.id,
              prayedAt: p.prayedAt,
              localDate: p.localDate,
              listContextNumber: p.listContextNumber,
              hasNote: p.note?.trim().isNotEmpty ?? false,
            ),
      ],
    );
  }

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

  /// updateSubject: printed text (contact check) and, for a name, the alias.
  Future<void> updateSubject(String id, {required String publicName, String? alias}) async {
    await Future<void>.delayed(latency);
    if (!online) throw const OfflineError();
    final s = _subjects.firstWhere((s) => s.id == id && !s.isSelf);
    final issue = validatePrinted(publicName, s.kind) ?? (s.isName ? validateAlias(alias) : null);
    if (issue != null) throw SubjectInputError(issue);
    final cleanAlias = alias == null ? '' : cleanText(alias);
    _replace(Subject(
      id: s.id,
      kind: s.kind,
      parentId: s.parentId,
      publicName: cleanText(publicName),
      alias: s.isName && cleanAlias.isNotEmpty ? cleanAlias : null,
      note: s.note,
      isSelf: s.isSelf,
      isCarried: s.isCarried,
      sortOrder: s.sortOrder,
      avatarTone: s.avatarTone,
      avatarPath: s.avatarPath,
      resolution: s.resolution,
      resolvedAt: s.resolvedAt,
      createdAt: s.createdAt,
      lastPrayed: s.lastPrayed,
    ));
  }

  /// setSelfName as an edit: free until first printed, then once per 7 days.
  Future<void> setSelfName(String name) async {
    await Future<void>.delayed(latency);
    if (!online) throw const OfflineError();
    final issue = validatePrinted(name, SubjectKind.soul);
    if (issue != null) throw SubjectInputError(issue);
    final self = _subjects.firstWhere((s) => s.isSelf);
    final printed = (_onLists[self.id] ?? const <int>{}).isNotEmpty;
    final last = _selfNameChangedAt;
    if (printed && last != null && _now().difference(last) < const Duration(days: 7)) {
      throw SelfNameTooSoonError(last.add(const Duration(days: 7)));
    }
    _selfNameChangedAt = _now();
    _replace(self.copyWith(publicName: cleanText(name)));
  }

  Future<void> markAnswered(String intentionId) async {
    await Future<void>.delayed(latency);
    if (!online) throw const OfflineError();
    final s = _subjects.firstWhere((s) => s.id == intentionId && s.isIntention && !s.isResolved);
    _replace(s.copyWith(resolution: Resolution.answered, resolvedAt: _now()));
  }

  /// Released + ARCHIVED: gone from the active subjects.
  Future<void> release(String intentionId) async {
    await Future<void>.delayed(latency);
    if (!online) throw const OfflineError();
    _subjects.firstWhere((s) => s.id == intentionId && s.isIntention && !s.isResolved);
    _subjects = [for (final s in _subjects) if (s.id != intentionId) s];
    _subjectsCtl.add(_subjects);
    _historyCtl.add(null);
  }

  /// ARCHIVED; a name's intentions go with it (the cascade).
  Future<void> archive(String id) async {
    await Future<void>.delayed(latency);
    if (!online) throw const OfflineError();
    final s = _subjects.firstWhere((s) => s.id == id);
    if (s.isSelf) throw ArgumentError('The self is never archived');
    _subjects = [for (final x in _subjects) if (x.id != id && x.parentId != id) x];
    _subjectsCtl.add(_subjects);
    _historyCtl.add(null);
  }

  void _replace(Subject next) {
    _subjects = [for (final s in _subjects) s.id == next.id ? next : s];
    _subjectsCtl.add(_subjects);
    _historyCtl.add(null);
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
    _prayers = [
      ..._prayers,
      SeedPrayer(
        id: p.id,
        prayedAt: p.prayedAt,
        localDate: p.localDate,
        listContextNumber: p.listContextNumber,
        subjectIds: linked,
        note: p.note,
      ),
    ];
    _historyCtl.add(null);

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
        final status = _myStatus;
        if (status != null && status.listId == list.id) {
          _myStatus = status.copyWith(prayersWithList: status.prayersWithList + 1);
          _myStatusCtl.add(_myStatus);
        }
      }
    }
  }

  void applyNote(String prayerId, String? note) {
    if (!_loggedPrayerIds.contains(prayerId)) return;
    _notes[prayerId] = note;
    _prayers = [for (final p in _prayers) p.id == prayerId ? p.withNote(note) : p];
    _historyCtl.add(null);
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

  /// Seals the current list in its weekday's wax (the video is published),
  /// or takes it back to "being filmed".
  void setSealed(bool sealed) {
    final list = _list;
    if (list == null) return;
    _list = CurrentList(
      id: list.id,
      listNumber: list.listNumber,
      listDate: list.listDate,
      isPublished: sealed,
      soulCount: list.soulCount,
      intentionCount: list.intentionCount,
      prayerCount: list.prayerCount,
      currentFrom: list.currentFrom,
      closesAt: list.closesAt,
      videoPublishedAt: sealed ? (list.videoPublishedAt ?? _now()) : null,
      videoPath: sealed ? (list.videoPath ?? 'videos/${list.id}.mp4') : null,
      sealVariant: sealed ? list.listDate.weekdayFromSunday : null,
    );
    _listCtl.add(_list);
    _historyCtl.add(null);
  }

  /// The morning routine, compressed: the current list closes and is
  /// assembled, and the next one becomes current (unsealed until its video).
  /// If you prayed with the closing list, you and your carried names are on
  /// the new one.
  void flipList() {
    final list = _list;
    if (list == null) return;
    final covered = (_myStatus?.prayersWithList ?? 0) > 0;
    final next = CurrentList(
      id: 'list-${list.listNumber + 1}',
      listNumber: list.listNumber + 1,
      listDate: list.listDate.addDays(1),
      isPublished: false,
      soulCount: list.soulCount + 37,
      intentionCount: list.intentionCount + 9,
      prayerCount: 0,
      currentFrom: _now(),
    );
    final tree = SubjectTree.of(_subjects);
    _closedLists[list.listNumber] = ListAppearance(
      listId: list.id,
      listNumber: list.listNumber,
      listDate: list.listDate,
      sealVariant: list.sealVariant,
      prayerCount: list.prayerCount,
    );
    // Names print with their carried intentions.
    final printed = [
      if (covered) ...[
        for (final s in carriedNames(tree)) ...[
          s,
          for (final i in tree.intentionsOf(s.id))
            if (isEffectivelyCarried(i, tree)) i,
        ],
      ],
    ];
    for (final s in printed) {
      (_onLists[s.id] ??= {}).add(next.listNumber);
    }
    _list = next;
    _myStatus = MyListStatus(
      listId: next.id,
      entries: [
        for (final s in printed)
          ListEntry(subjectId: s.id, publicName: s.publicName, isName: s.isName, isSelf: s.isSelf),
      ],
    );
    _listCtl.add(_list);
    _myStatusCtl.add(_myStatus);
    _historyCtl.add(null);
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
    _myStatusCtl.close();
    _statsCtl.close();
    _historyCtl.close();
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

  @override
  Stream<SubjectHistory?> watchHistory(String subjectId) => backend.watchHistory(subjectId);

  @override
  Future<void> updateSubject(String id, {required String publicName, String? alias}) =>
      backend.updateSubject(id, publicName: publicName, alias: alias);

  @override
  Future<void> setSelfName(String name) => backend.setSelfName(name);

  @override
  Future<void> markAnswered(String intentionId) => backend.markAnswered(intentionId);

  @override
  Future<void> release(String intentionId) => backend.release(intentionId);

  @override
  Future<void> archive(String id) => backend.archive(id);
}

class MockListRepository implements ListRepository {
  MockListRepository(this.backend);
  final MockBackend backend;

  @override
  Stream<CurrentList?> watchCurrentList() => backend.watchList();

  @override
  Stream<MyListStatus?> watchMyStatus() => backend.watchMyStatus();
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
