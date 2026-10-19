/// A calendar day with no time or zone (`Prayer.localDate`,
/// `User.lastListLocalDate`). Streaks and "Prayed today" compare these, never
/// instants (streaks-reminders.md).
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.of(DateTime t) => LocalDate(t.year, t.month, t.day);

  /// Parses `YYYY-MM-DD`.
  factory LocalDate.parse(String s) {
    final parts = s.split('-').map(int.parse).toList();
    return LocalDate(parts[0], parts[1], parts[2]);
  }

  final int year;
  final int month;
  final int day;

  /// Midnight UTC of this day; only for day arithmetic and formatting.
  DateTime toUtc() => DateTime.utc(year, month, day);

  LocalDate addDays(int days) => LocalDate.of(toUtc().add(Duration(days: days)));

  /// Whole days from [other] to this (positive when this is later).
  int daysSince(LocalDate other) => toUtc().difference(other.toUtc()).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// 0 = Sunday … 6 = Saturday — the sealVariant weekday convention.
  int get weekdayFromSunday => toUtc().weekday % 7;

  @override
  int compareTo(LocalDate other) =>
      year != other.year ? year - other.year : (month != other.month ? month - other.month : day - other.day);

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
