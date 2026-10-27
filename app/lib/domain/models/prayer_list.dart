import 'local_date.dart';

/// The current daily list: getCurrentListMeta, with the live `prayerCount` and
/// `closesAt` stitched in from RTDB `/lists/current`. Never names.
class CurrentList {
  const CurrentList({
    required this.id,
    required this.listNumber,
    required this.listDate,
    required this.isPublished,
    required this.soulCount,
    required this.intentionCount,
    required this.prayerCount,
    this.currentFrom,
    this.closesAt,
    this.videoPublishedAt,
    this.videoPath,
    this.sealVariant,
  });

  final String id;
  final int listNumber;
  final LocalDate listDate;

  /// status == "published".
  final bool isPublished;
  final DateTime? currentFrom;

  /// The exact cutoff (set ~5 min before assembly). A prayer counts for this
  /// list if it STARTED before it.
  final DateTime? closesAt;

  /// null → "being filmed" placeholder.
  final DateTime? videoPublishedAt;
  final String? videoPath;

  /// 0 = Sunday … 6 = Saturday; null → the unsealed state.
  final int? sealVariant;

  /// People on the list ("Hold the 4,345 on List 52").
  final int soulCount;
  final int intentionCount;
  final int prayerCount;

  bool get isSealed => sealVariant != null;

  /// The list a prayer for this one carries the user onto.
  int get nextListNumber => listNumber + 1;

  CurrentList copyWith({int? prayerCount, DateTime? closesAt}) => CurrentList(
        id: id,
        listNumber: listNumber,
        listDate: listDate,
        isPublished: isPublished,
        soulCount: soulCount,
        intentionCount: intentionCount,
        prayerCount: prayerCount ?? this.prayerCount,
        currentFrom: currentFrom,
        closesAt: closesAt ?? this.closesAt,
        videoPublishedAt: videoPublishedAt,
        videoPath: videoPath,
        sealVariant: sealVariant,
      );
}

/// getMyListStatus for one list: which of yours are printed on it, and
/// whether you've prayed with it (the gate for the next list).
class MyListStatus {
  const MyListStatus({required this.listId, this.entries = const [], this.prayersWithList = 0});

  final String listId;

  /// Your entries on the list (not EXCLUDED), names and intentions.
  final List<ListEntry> entries;

  /// Your prayers with `communityList` = this list. Any → you (and your
  /// carried names) are on the next list.
  final int prayersWithList;

  MyListStatus copyWith({List<ListEntry>? entries, int? prayersWithList}) => MyListStatus(
        listId: listId,
        entries: entries ?? this.entries,
        prayersWithList: prayersWithList ?? this.prayersWithList,
      );
}

/// One of your entries on a printed list. [subjectId] is null when the
/// subject was deleted after printing (the entry keeps its printed name).
class ListEntry {
  const ListEntry({required this.publicName, required this.isName, this.subjectId, this.isSelf = false});

  final String? subjectId;
  final String publicName;
  final bool isName;
  final bool isSelf;
}
