// Home's view state: search + filter (persisting across nav and prayer
// modes), the visible rows, and the community card (its carry status,
// presence, and closing notice).

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
  return ref.watch(subjectTreeProvider).whenData(
        (tree) => visibleRows(tree, today: today, query: query.text, filter: query.filter),
      );
});

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
