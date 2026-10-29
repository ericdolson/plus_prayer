// Home's view state: search + filter (persisting across nav and prayer
// modes), the visible rows, and the community card (its carry status,
// presence, and closing notice).
//
// Linger then fold (design-direction.md §4): under Still to hold, the rows
// just held in a prayer stay ~1.2 s after Amen with their gold ring, then
// fold away. Only rows that would otherwise be gone fold; a name that stays
// as context for an unheld intention just stays. The community card does the
// same when the list was held ([cardLingerKey]).
//
// The card under filters and search (design-direction.md §6): shown under
// All and Carried; under Still to hold only until you've prayed with the
// list today; hidden while search has text (results only).

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/models/prayer_list.dart';
import '../domain/models/subject.dart';
import '../domain/rules/card_carry.dart';
import '../domain/rules/carry.dart';
import '../domain/rules/home_filter.dart';
import '../domain/rules/presence.dart';
import '../domain/rules/streak.dart';
import 'providers.dart';

class HomeQuery {
  const HomeQuery({this.text = '', this.filter = HomeFilter.all, this.searchOpen = false});

  final String text;
  final HomeFilter filter;
  final bool searchOpen;

  HomeQuery copyWith({String? text, HomeFilter? filter, bool? searchOpen}) => HomeQuery(
        text: text ?? this.text,
        filter: filter ?? this.filter,
        searchOpen: searchOpen ?? this.searchOpen,
      );
}

final homeQueryProvider = NotifierProvider<HomeQueryController, HomeQuery>(HomeQueryController.new);

class HomeQueryController extends Notifier<HomeQuery> {
  @override
  HomeQuery build() => const HomeQuery();

  void setText(String text) => state = state.copyWith(text: text);
  void setFilter(HomeFilter filter) => state = state.copyWith(filter: filter);
  void openSearch() => state = state.copyWith(searchOpen: true);
  void closeSearch() => state = state.copyWith(searchOpen: false, text: '');
}

final homeRowsProvider = Provider<AsyncValue<List<HomeRow>>>((ref) {
  final query = ref.watch(homeQueryProvider);
  final today = ref.watch(todayProvider);
  final keep = ref.watch(lingerProvider).keys.toSet();
  return ref.watch(subjectTreeProvider).whenData(
        (tree) => visibleRows(tree, today: today, query: query.text, filter: query.filter, keep: keep),
      );
});

/// Rows on their way out: folding now, and gone without the linger.
final foldingRowsProvider = Provider<Set<String>>((ref) {
  final linger = ref.watch(lingerProvider);
  final folding = {
    for (final MapEntry(:key, :value) in linger.entries)
      if (value == LingerPhase.folding) key,
  };
  if (folding.isEmpty) return const {};
  final tree = ref.watch(subjectTreeProvider).value;
  if (tree == null) return const {};
  final query = ref.watch(homeQueryProvider);
  final staying = visibleRows(
    tree,
    today: ref.watch(todayProvider),
    query: query.text,
    filter: query.filter,
    keep: linger.keys.toSet().difference(folding),
  ).map((r) => r.subject.id).toSet();
  return folding.difference(staying);
});

/// With a filter active: how many items the query matches under All (search's
/// filtered empty state); null without a filter or a query.
final searchMatchesInAllProvider = Provider<int?>((ref) {
  final query = ref.watch(homeQueryProvider);
  final text = query.text.trim();
  if (query.filter == HomeFilter.all || text.isEmpty) return null;
  final tree = ref.watch(subjectTreeProvider).value;
  if (tree == null) return null;
  return matchesInAll(tree, text, ref.watch(todayProvider));
});

/// Item counts per filter, for the filter menu only.
final filterCountsProvider = Provider<Map<HomeFilter, int>?>((ref) {
  final tree = ref.watch(subjectTreeProvider).value;
  if (tree == null) return null;
  final today = ref.watch(todayProvider);
  return {for (final f in HomeFilter.values) f: filterCount(tree, f, today)};
});

/// The community card's key in [lingerProvider].
const cardLingerKey = 'community-card';

final communityCardShownProvider = Provider<bool>((ref) {
  final query = ref.watch(homeQueryProvider);
  if (query.text.trim().isNotEmpty) return false;
  if (query.filter != HomeFilter.stillToHold) return true;
  final card = ref.watch(communityCardProvider);
  return card != null && (!card.prayedWithList || ref.watch(lingerProvider).containsKey(cardLingerKey));
});

/// Folding away under Still to hold, after the list was held.
final communityCardFoldingProvider =
    Provider<bool>((ref) => ref.watch(lingerProvider)[cardLingerKey] == LingerPhase.folding);

enum LingerPhase { lingering, folding }

final lingerProvider = NotifierProvider<LingerController, Map<String, LingerPhase>>(LingerController.new);

class LingerController extends Notifier<Map<String, LingerPhase>> {
  final _timers = <Timer>[];

  /// Which batch last held each id, so an earlier batch's timers leave a
  /// re-held row alone.
  final _batchOf = <String, int>{};
  var _batches = 0;

  @override
  Map<String, LingerPhase> build() {
    ref.onDispose(() {
      for (final t in _timers) {
        t.cancel();
      }
    });
    return const {};
  }

  /// Keep [ids] for [linger], then fold them over [fold]; the UI passes its
  /// motion (a plain fade with Reduce Motion).
  void hold(Iterable<String> ids, {required Duration linger, required Duration fold}) {
    final batch = ids.toSet();
    if (batch.isEmpty) return;
    final n = ++_batches;
    for (final id in batch) {
      _batchOf[id] = n;
    }
    bool mine(String id) => _batchOf[id] == n;
    state = {...state, for (final id in batch) id: LingerPhase.lingering};
    _timers
      ..removeWhere((t) => !t.isActive)
      ..add(Timer(linger, () => state = {...state, for (final id in batch.where(mine)) id: LingerPhase.folding}))
      ..add(Timer(linger + fold, () {
        final done = batch.where(mine).toSet();
        _batchOf.removeWhere((id, _) => done.contains(id));
        state = {...state}..removeWhere((id, _) => done.contains(id));
      }));
  }
}

/// Items added this session that the pool couldn't carry: their row says so
/// once ("Not on the list · all 15 places in use") — never a silent choice.
final justAddedNotCarriedProvider =
    NotifierProvider<JustAddedNotCarried, Set<String>>(JustAddedNotCarried.new);

class JustAddedNotCarried extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String id) => state = {...state, id};
}

class CommunityCardModel {
  const CommunityCardModel({
    required this.list,
    required this.carried,
    required this.prayedWithList,
    required this.carry,
  });

  final CurrentList list;

  /// You first, then effectively carried names, in the user's order.
  final List<Subject> carried;

  /// Prayed with the list today (local day): the card's gold border, until
  /// local midnight — never cleared by the flip.
  final bool prayedWithList;

  /// Today's names and tomorrow's status (domain/rules/card_carry.dart).
  final CardCarry carry;
}

final communityCardProvider = Provider<CommunityCardModel?>((ref) {
  final list = ref.watch(currentListProvider).value;
  final tree = ref.watch(subjectTreeProvider).value;
  final header = ref.watch(headerProvider).value;
  if (list == null || tree == null) return null;
  final today = ref.watch(todayProvider);
  return CommunityCardModel(
    list: list,
    carried: carriedNames(tree),
    prayedWithList: header != null && prayedWithListToday(header, today),
    carry: cardCarry(
      tree: tree,
      list: list,
      status: ref.watch(myListStatusProvider).value,
      localPrayers: ref.watch(localPrayersProvider).value ?? const [],
      header: header,
      today: today,
    ),
  );
});

final presenceLineProvider = Provider<PresenceLine?>((ref) {
  final stats = ref.watch(liveStatsProvider).value;
  if (stats == null) return null;
  return presenceLine(stats, ref.watch(configProvider).presenceDisplayThreshold);
});

/// Minutes until the list closes, during the 5-minute window, for anyone who
/// hasn't prayed with it today; null otherwise.
final closingSoonMinutesProvider = Provider<int?>((ref) {
  final row = ref.watch(communityCardProvider);
  final closesAt = row?.list.closesAt;
  if (row == null || closesAt == null || row.prayedWithList) return null;
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  final left = closesAt.difference(now);
  if (left.isNegative || left > const Duration(minutes: 5)) return null;
  return (left.inSeconds / 60).ceil().clamp(1, 5);
});

/// The pool size the user's carry is measured against right now (effective
/// entitlement; free = 1).
final poolLimitProvider = Provider<int>((ref) {
  final header = ref.watch(headerProvider).value;
  if (header == null) return freeLimit;
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
  return hasActiveEntitlement(header, now) ? header.includeLimit : freeLimit;
});
