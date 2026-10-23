/// getMyReminders: one ReminderPreference per preset slot. Synced on the
/// server, scheduled on the device as local notifications (notifications.md).
/// Custom reminders are later; the slot exists so the table supports them.
enum ReminderSlot { morning, midday, evening, custom }

/// A wall-clock time with no date or zone (`ReminderPreference.localTime`,
/// "HH:mm").
class ClockTime implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute);

  /// Parses `HH:mm` (seconds, if present, are ignored).
  factory ClockTime.parse(String s) {
    final parts = s.split(':').map(int.parse).toList();
    return ClockTime(parts[0], parts[1]);
  }

  final int hour;
  final int minute;

  String toIso() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ClockTime other) => hour != other.hour ? hour - other.hour : minute - other.minute;

  @override
  bool operator ==(Object other) => other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toIso();
}

class Reminder {
  const Reminder({required this.id, required this.slot, required this.enabled, required this.localTime, this.label});

  final String id;
  final ReminderSlot slot;
  final bool enabled;
  final ClockTime localTime;

  /// Custom reminders only.
  final String? label;

  Reminder copyWith({bool? enabled, ClockTime? localTime}) => Reminder(
        id: id,
        slot: slot,
        enabled: enabled ?? this.enabled,
        localTime: localTime ?? this.localTime,
        label: label,
      );
}
