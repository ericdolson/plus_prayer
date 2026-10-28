import 'local_date.dart';

/// One finished prayer, as sent to `logPrayer` (OPERATIONS.md §C). Written
/// ONCE, at the final Amen. Immutable except for the note.
class NewPrayer {
  const NewPrayer({
    required this.id,
    required this.startedAt,
    required this.prayedAt,
    required this.durationSeconds,
    required this.localDate,
    required this.timezone,
    required this.listContextNumber,
    required this.subjectIds,
    this.checkedAt = const {},
    this.communityListId,
    this.note,
  });

  /// Client-generated UUID — a resend is a no-op on the server.
  final String id;
  final DateTime startedAt;

  /// End time.
  final DateTime prayedAt;
  final int durationSeconds;

  /// Device local date and zone at the START.
  final LocalDate localDate;
  final String timezone;

  /// Set iff the list was included (the list current at start).
  final String? communityListId;

  /// The list current at start, always set.
  final int listContextNumber;
  final String? note;

  /// Held items. The server also links each intention's name.
  final List<String> subjectIds;

  /// When each held item was checked (subject id → time), for
  /// `PrayerSubjectLink.checkedAt` (schema-brief §12). Sent per item once the
  /// regenerated SDK's `logPrayer` takes it. An item restored from an older
  /// draft may have none.
  final Map<String, DateTime> checkedAt;

  bool get includesList => communityListId != null;

  Map<String, Object?> toJson() => {
        'id': id,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'prayedAt': prayedAt.toUtc().toIso8601String(),
        'durationSeconds': durationSeconds,
        'localDate': localDate.toString(),
        'timezone': timezone,
        'communityListId': communityListId,
        'listContextNumber': listContextNumber,
        'note': note,
        'subjectIds': subjectIds,
        'checkedAt': {for (final e in checkedAt.entries) e.key: e.value.toUtc().toIso8601String()},
      };

  factory NewPrayer.fromJson(Map<String, Object?> json) => NewPrayer(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        prayedAt: DateTime.parse(json['prayedAt'] as String),
        durationSeconds: json['durationSeconds'] as int,
        localDate: LocalDate.parse(json['localDate'] as String),
        timezone: json['timezone'] as String,
        communityListId: json['communityListId'] as String?,
        listContextNumber: json['listContextNumber'] as int,
        note: json['note'] as String?,
        subjectIds: [...(json['subjectIds'] as List).cast<String>()],
        // Absent on writes queued before checkedAt existed.
        checkedAt: {
          for (final e in (json['checkedAt'] as Map? ?? const {}).entries)
            e.key as String: DateTime.parse(e.value as String),
        },
      );
}
