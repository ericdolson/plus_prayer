// One prayer session (prayer-flow.md, app-brief §3 "In-prayer mode").
//
// idle ──start──▶ praying ──Amen──▶ (invitation) ──Amen──▶ closing ──▶ idle
//                    │                    │
//                    └──Cancel (discard)──┘
//
// - Cancel lives in the header, top-left (design-direction.md §4): past
//   ~30 s it asks "Discard this prayer?" first; under that, it discards at
//   once.
//
// - Prayer happens in place: Home stays, the mode changes.
// - Amen is available after the minimum (5 s, `/config`); before it only Cancel
//   exits, and nothing is logged.
// - Amen without the list (when the user hasn't prayed with it today) opens
//   the invitation. Tapping it holds the list and runs the same 5 s ring; the
//   invitation EXTENDS the same prayer — one Prayer, written once, at the final
//   Amen.
// - The list current at START is the one the prayer counts for.
// - The in-progress draft lives in the presence node; back within ~30 min →
//   resume quietly; later → "Welcome back. Finish your prayer from 7:42?".

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/models/live.dart';
import '../domain/models/local_date.dart';
import '../domain/models/prayer.dart';
import '../domain/models/subject.dart';
import '../domain/rules/selection.dart';
import '../domain/rules/streak.dart';
import '../domain/rules/subject_tree.dart';
import 'providers.dart';

enum PrayerPhase {
  idle,

  /// In prayer: halo, prayer bar, rows are checkboxes.
  praying,

  /// Amen was said without the list: the quiet invitation to hold it.
  invitation,

  /// Written. Offers "Add a note", then the closing line.
  closing,
}

class PrayerSessionState {
  const PrayerSessionState({
    this.phase = PrayerPhase.idle,
    this.prayerId,
    this.startedAt,
    this.localDate,
    this.timezone,
    this.selection = PrayerSelection.empty,
    this.listId,
    this.listNumber,
    this.listHoldingSince,
    this.backgroundedAt,
    this.awaitingWelcomeBack = false,
    this.logged,
  });

  static const idle = PrayerSessionState();

  final PrayerPhase phase;

  /// Client UUID, chosen at start (also the draft's `prayerId`).
  final String? prayerId;
  final DateTime? startedAt;

  /// Local date and zone at START.
  final LocalDate? localDate;
  final String? timezone;
  final PrayerSelection selection;

  /// The list current at start — the one this prayer counts for.
  final String? listId;
  final int? listNumber;

  /// When the user tapped the invitation (its ring runs from here).
  final DateTime? listHoldingSince;

  /// Set while the app is in the background.
  final DateTime? backgroundedAt;

  /// Came back after the resume window: ask before continuing.
  final bool awaitingWelcomeBack;

  /// The prayer as written, while closing.
  final NewPrayer? logged;

  bool get isActive => phase == PrayerPhase.praying || phase == PrayerPhase.invitation;

  PrayerSessionState copyWith({
    PrayerPhase? phase,
    PrayerSelection? selection,
    DateTime? listHoldingSince,
    DateTime? backgroundedAt,
    bool clearBackgroundedAt = false,
    bool? awaitingWelcomeBack,
    NewPrayer? logged,
  }) =>
      PrayerSessionState(
        phase: phase ?? this.phase,
        prayerId: prayerId,
        startedAt: startedAt,
        localDate: localDate,
        timezone: timezone,
        selection: selection ?? this.selection,
        listId: listId,
        listNumber: listNumber,
        listHoldingSince: listHoldingSince ?? this.listHoldingSince,
        backgroundedAt: clearBackgroundedAt ? null : (backgroundedAt ?? this.backgroundedAt),
        awaitingWelcomeBack: awaitingWelcomeBack ?? this.awaitingWelcomeBack,
        logged: logged ?? this.logged,
      );
}

final prayerSessionProvider =
    NotifierProvider<PrayerSessionController, PrayerSessionState>(PrayerSessionController.new);

class PrayerSessionController extends Notifier<PrayerSessionState> {
  Timer? _heartbeat;

  @override
  PrayerSessionState build() {
    ref.onDispose(() => _heartbeat?.cancel());
    return PrayerSessionState.idle;
  }

  DateTime get _now => ref.read(clockProvider)();
  AppConfig get _config => ref.read(configProvider);
  SubjectTree? get _tree => ref.read(subjectTreeProvider).value;

  /// Begin praying. [focusId] pre-checks one item ("Pray" from a detail
  /// page); [withList] pre-checks the list (the closing banner).
  Future<void> start({String? focusId, bool withList = false}) async {
    if (state.isActive) return;
    final now = _now;
    final list = ref.read(currentListProvider).value;
    final tz = await ref.read(timezoneProvider.future);
    var selection = PrayerSelection(listIncluded: withList && list != null);
    final tree = _tree;
    if (focusId != null && tree != null) selection = selection.hold(focusId, tree).stampedAt(now);
    state = PrayerSessionState(
      phase: PrayerPhase.praying,
      prayerId: ref.read(idGeneratorProvider)(),
      startedAt: now,
      localDate: LocalDate.of(now),
      timezone: tz,
      selection: selection,
      listId: list?.id,
      listNumber: list?.listNumber,
    );
    _writeDraft();
    _startHeartbeat();
  }

  /// Tap on a subject row in prayer.
  void toggle(String subjectId) {
    final tree = _tree;
    if (!state.isActive || tree == null) return;
    state = state.copyWith(selection: state.selection.toggle(subjectId, tree).stampedAt(_now));
    _writeDraft();
  }

  /// Tap on the pinned list row in prayer.
  void toggleList() {
    if (!state.isActive || state.listId == null) return;
    state = state.copyWith(selection: state.selection.withList(!state.selection.listIncluded));
    _writeDraft();
  }

  bool canAmen(DateTime now) => state.startedAt != null && now.difference(state.startedAt!) >= _config.minPrayer;

  /// The FAB's Amen.
  Future<void> amen() async {
    if (state.phase != PrayerPhase.praying || !canAmen(_now)) return;
    if (_shouldInvite()) {
      state = state.copyWith(phase: PrayerPhase.invitation);
      return;
    }
    await _finish(_now);
  }

  bool _shouldInvite() {
    if (state.selection.listIncluded || state.listId == null) return false;
    final header = ref.read(headerProvider).value;
    final today = ref.read(todayProvider);
    return header == null || !prayedWithListToday(header, today);
  }

  /// Tap on the invitation: hold the list too; the ring runs from now.
  void holdList() {
    if (state.phase != PrayerPhase.invitation || state.listHoldingSince != null) return;
    state = state.copyWith(
      selection: state.selection.withList(true),
      listHoldingSince: _now,
    );
    _writeDraft();
  }

  bool canAmenWithList(DateTime now) =>
      state.listHoldingSince != null && now.difference(state.listHoldingSince!) >= _config.minPrayer;

  /// The invitation's Amen: with the list once its ring has run, or without
  /// it if the user didn't tap.
  Future<void> amenFromInvitation() async {
    if (state.phase != PrayerPhase.invitation) return;
    final now = _now;
    if (state.listHoldingSince != null && !canAmenWithList(now)) return;
    await _finish(now);
  }

  /// Past this, Cancel asks before discarding.
  static const confirmDiscardAfter = Duration(seconds: 30);

  bool shouldConfirmDiscard(DateTime now) =>
      state.startedAt != null && now.difference(state.startedAt!) > confirmDiscardAfter;

  /// Cancel — discard. Nothing is logged.
  Future<void> cancel() async {
    if (!state.isActive) return;
    _heartbeat?.cancel();
    state = PrayerSessionState.idle;
    await ref.read(liveRepositoryProvider).writeDraft(null);
  }

  Future<void> addNote(String? note) async {
    final logged = state.logged;
    final text = note?.trim();
    if (logged == null || text == null || text.isEmpty) return;
    await ref.read(prayerRepositoryProvider).updateNote(logged.id, text);
  }

  /// Leave the closing moment.
  void close() {
    if (state.phase == PrayerPhase.closing) state = PrayerSessionState.idle;
  }

  // ---- Backgrounding -------------------------------------------------------

  void onBackground() {
    if (!state.isActive || state.backgroundedAt != null) return;
    state = state.copyWith(backgroundedAt: _now);
    _heartbeat?.cancel();
    _writeDraft(inForeground: false);
  }

  void onForeground() {
    final left = state.backgroundedAt;
    if (!state.isActive || left == null) return;
    if (_now.difference(left) > _config.draftResume) {
      state = state.copyWith(awaitingWelcomeBack: true);
      return;
    }
    state = state.copyWith(clearBackgroundedAt: true);
    _writeDraft();
    _startHeartbeat();
  }

  /// "Welcome back" → [Amen]: duration runs until they left + up to 30 min.
  Future<void> welcomeBackAmen() async {
    final left = state.backgroundedAt;
    if (!state.awaitingWelcomeBack || left == null) return;
    final end = left.add(_config.draftResume);
    await _finish(end.isBefore(_now) ? end : _now);
  }

  /// "Welcome back" → [Discard].
  Future<void> welcomeBackDiscard() => cancel();

  /// On launch: pick up a draft this device left open (app killed).
  Future<void> restoreDraft() async {
    if (state.phase != PrayerPhase.idle) return;
    final draft = await ref.read(liveRepositoryProvider).readDraft();
    if (draft == null) return;
    final list = ref.read(currentListProvider).value;
    final tree = _tree;
    var selection = PrayerSelection(listIncluded: draft.listIncluded);
    for (final id in draft.itemIds) {
      if (tree?[id] != null) {
        selection = PrayerSelection(held: {...selection.held, id}, listIncluded: selection.listIncluded);
      }
    }
    state = PrayerSessionState(
      phase: PrayerPhase.praying,
      prayerId: draft.prayerId,
      startedAt: draft.startedAt,
      localDate: draft.localDate,
      timezone: draft.timezone,
      selection: selection,
      listId: list?.id,
      listNumber: list?.listNumber,
      backgroundedAt: draft.lastActiveAt,
    );
    onForeground();
  }

  // ---- Internals -------------------------------------------------------------

  Future<void> _finish(DateTime end) async {
    final s = state;
    final startedAt = s.startedAt;
    if (startedAt == null || s.prayerId == null) return;
    _heartbeat?.cancel();
    var seconds = end.difference(startedAt).inSeconds;
    final cap = _config.durationCap.inSeconds;
    if (seconds > cap) seconds = cap;
    if (seconds < _config.minPrayerSeconds) seconds = _config.minPrayerSeconds;

    final tree = _tree;
    final held = [
      // Stable order: as the user sees them.
      if (tree != null)
        for (final name in tree.names) ...[
          if (s.selection.isHeld(name.id)) name.id,
          for (final Subject i in tree.intentionsOf(name.id))
            if (s.selection.isHeld(i.id)) i.id,
        ],
    ];
    final prayer = NewPrayer(
      id: s.prayerId!,
      startedAt: startedAt,
      prayedAt: end,
      durationSeconds: seconds,
      localDate: s.localDate ?? LocalDate.of(startedAt),
      timezone: s.timezone ?? 'UTC',
      communityListId: s.selection.listIncluded ? s.listId : null,
      listContextNumber: s.listNumber ?? 0,
      subjectIds: held,
      checkedAt: {
        for (final id in held)
          if (s.selection.checkedAt[id] case final at?) id: at,
      },
    );
    state = s.copyWith(phase: PrayerPhase.closing, logged: prayer, awaitingWelcomeBack: false);
    await ref.read(prayerRepositoryProvider).logPrayer(prayer);
    await ref.read(liveRepositoryProvider).writeDraft(null);
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(minutes: 1), (_) => _writeDraft());
  }

  void _writeDraft({bool inForeground = true}) {
    final s = state;
    if (!s.isActive || s.prayerId == null || s.startedAt == null) return;
    unawaited(ref.read(liveRepositoryProvider).writeDraft(PrayerDraft(
          prayerId: s.prayerId!,
          startedAt: s.startedAt!,
          lastActiveAt: _now,
          inForeground: inForeground,
          listIncluded: s.selection.listIncluded,
          itemIds: s.selection.held.toList(),
          localDate: s.localDate!,
          timezone: s.timezone!,
        )));
  }
}
