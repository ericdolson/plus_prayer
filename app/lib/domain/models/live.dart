import 'local_date.dart';

/// RTDB `/stats/live` (server-written, public-read).
class LiveStats {
  const LiveStats({
    required this.prayingNow,
    required this.prayedLastHour,
    required this.prayedToday,
    this.updatedAt,
  });

  static const empty = LiveStats(prayingNow: 0, prayedLastHour: 0, prayedToday: 0);

  /// People (not devices) in prayer right now.
  final int prayingNow;
  final int prayedLastHour;
  final int prayedToday;
  final DateTime? updatedAt;
}

/// RTDB `/config`, overlaid on these compiled-in defaults (schema-brief §5;
/// same values as backend/functions/config/client-config.json).
class AppConfig {
  const AppConfig({
    this.graceCap = 2,
    this.graceIntervalDays = 7,
    this.presenceDisplayThreshold = 10,
    this.minAppVersion = '0.0.0',
    this.minPrayerSeconds = 5,
    this.draftResumeMinutes = 30,
    this.autoSaveHours = 6,
    this.durationCapHours = 4,
  });

  static const defaults = AppConfig();

  final int graceCap;
  final int graceIntervalDays;
  final int presenceDisplayThreshold;
  final String minAppVersion;
  final int minPrayerSeconds;
  final int draftResumeMinutes;
  final int autoSaveHours;
  final int durationCapHours;

  Duration get minPrayer => Duration(seconds: minPrayerSeconds);
  Duration get draftResume => Duration(minutes: draftResumeMinutes);
  Duration get durationCap => Duration(hours: durationCapHours);

  /// Overlay whatever `/config` holds (wrong types are ignored).
  factory AppConfig.fromJson(Map<String, Object?>? json) {
    const d = defaults;
    T pick<T>(String key, T fallback) {
      final v = json?[key];
      return v is T ? v : fallback;
    }

    return AppConfig(
      graceCap: pick('graceCap', d.graceCap),
      graceIntervalDays: pick('graceIntervalDays', d.graceIntervalDays),
      presenceDisplayThreshold: pick('presenceDisplayThreshold', d.presenceDisplayThreshold),
      minAppVersion: pick('minAppVersion', d.minAppVersion),
      minPrayerSeconds: pick('minPrayerSeconds', d.minPrayerSeconds),
      draftResumeMinutes: pick('draftResumeMinutes', d.draftResumeMinutes),
      autoSaveHours: pick('autoSaveHours', d.autoSaveHours),
      durationCapHours: pick('durationCapHours', d.durationCapHours),
    );
  }
}

/// The in-progress prayer as written to `/presence/{uid}/{deviceId}`
/// (schema-brief §3). IDs only — never names. Per device.
class PrayerDraft {
  const PrayerDraft({
    required this.prayerId,
    required this.startedAt,
    required this.lastActiveAt,
    required this.inForeground,
    required this.listIncluded,
    required this.itemIds,
    required this.localDate,
    required this.timezone,
  });

  final String prayerId;
  final DateTime startedAt;
  final DateTime lastActiveAt;
  final bool inForeground;
  final bool listIncluded;
  final List<String> itemIds;
  final LocalDate localDate;
  final String timezone;

  Map<String, Object?> toJson() => {
        'prayerId': prayerId,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'lastActiveAt': lastActiveAt.toUtc().toIso8601String(),
        'inForeground': inForeground,
        'listIncluded': listIncluded,
        'itemIds': itemIds,
        'localDate': localDate.toString(),
        'timezone': timezone,
      };

  factory PrayerDraft.fromJson(Map<String, Object?> json) => PrayerDraft(
        prayerId: json['prayerId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
        inForeground: json['inForeground'] as bool? ?? false,
        listIncluded: json['listIncluded'] as bool? ?? false,
        itemIds: [...(json['itemIds'] as List? ?? const []).cast<String>()],
        localDate: LocalDate.parse(json['localDate'] as String),
        timezone: json['timezone'] as String,
      );
}
