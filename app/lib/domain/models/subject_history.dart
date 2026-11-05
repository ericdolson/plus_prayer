import 'local_date.dart';

/// getSubjectDetail's history half (stats-history.md, OPERATIONS.md): the
/// lists a subject was printed on and the user's own prayers that held it.
/// The subject row itself comes from getMySubjects (the tree). The client
/// buckets both into period rows (`rules/history.dart`).
class SubjectHistory {
  const SubjectHistory({required this.subjectId, this.entries = const [], this.prayers = const []});

  final String subjectId;

  /// Printed entries only (not EXCLUDED), any order.
  final List<ListAppearance> entries;

  /// The user's prayers that link this subject (an intention's prayers link
  /// its name too, server-side), any order.
  final List<SubjectPrayer> prayers;

  SubjectHistory copyWith({List<ListAppearance>? entries, List<SubjectPrayer>? prayers}) => SubjectHistory(
        subjectId: subjectId,
        entries: entries ?? this.entries,
        prayers: prayers ?? this.prayers,
      );
}

/// One list the subject was printed on: a bead.
class ListAppearance {
  const ListAppearance({
    required this.listId,
    required this.listNumber,
    required this.listDate,
    required this.prayerCount,
    this.sealVariant,
    this.isCurrent = false,
  });

  final String listId;
  final int listNumber;
  final LocalDate listDate;

  /// 0 = Sunday … 6 = Saturday; null while unsealed ("being filmed").
  final int? sealVariant;

  /// `PrayerList.prayerCount`: frozen once closed; live for the current list
  /// (stitched from RTDB on the client).
  final int prayerCount;
  final bool isCurrent;

  ListAppearance copyWith({int? sealVariant, bool clearSeal = false, int? prayerCount, bool? isCurrent}) =>
      ListAppearance(
        listId: listId,
        listNumber: listNumber,
        listDate: listDate,
        sealVariant: clearSeal ? null : (sealVariant ?? this.sealVariant),
        prayerCount: prayerCount ?? this.prayerCount,
        isCurrent: isCurrent ?? this.isCurrent,
      );
}

/// One of the user's prayers that held the subject.
class SubjectPrayer {
  const SubjectPrayer({
    required this.id,
    required this.prayedAt,
    required this.localDate,
    required this.listContextNumber,
    this.hasNote = false,
  });

  final String id;
  final DateTime prayedAt;

  /// The device's local date at the prayer's START.
  final LocalDate localDate;
  final int listContextNumber;
  final bool hasNote;
}
