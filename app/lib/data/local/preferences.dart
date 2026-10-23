// Device-local preferences (not synced): things that must be known before the
// first frame, like the appearance. Account settings that sync across devices
// live on the User record (screens.md) and go through UserRepository.

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class Preferences {
  String? getString(String key);
  Future<void> setString(String key, String value);
}

class MemoryPreferences implements Preferences {
  final _values = <String, String>{};

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async => _values[key] = value;
}

/// Backed by [SharedPreferences], loaded once at startup so reads are sync.
class DevicePreferences implements Preferences {
  DevicePreferences(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
}
