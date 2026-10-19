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
