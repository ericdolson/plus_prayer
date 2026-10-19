import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class DateWrapper {
  late DateTime timestamp;

  DateWrapper({DateTime? timestamp}) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  String get dateKey {
    return DateTime.now().toIso8601String().split('T').first;
  }

  String get timezoneName {
    return tz.local.name;
  }
}

String makeDateKey(DateTime dateTime) {
  return dateTime.toIso8601String().split('T').first;
}

String currentDateKey() {
  return makeDateKey(DateTime.now());
}

String currentTimezone() {
  return tz.local.name;
}

String getDateOfTimestampAtLocation(DateTime timestamp, String timezone) {
  final location = tz.getLocation(timezone);
  final localTime = tz.TZDateTime.from(timestamp, location);
  return DateFormat('yyyy-MM-dd').format(localTime);
}
