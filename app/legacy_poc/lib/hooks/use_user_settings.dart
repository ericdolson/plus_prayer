import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorSchemeData {
  final String label;
  final IconData icon;

  const ColorSchemeData(this.label, this.icon);
}

enum ColorScheme {
  dark(ColorSchemeData('Dark', Icons.dark_mode_rounded)),
  light(ColorSchemeData('Light', Icons.light_mode_outlined)),
  system(ColorSchemeData('System', Icons.brightness_4_outlined));

  final ColorSchemeData meta;

  const ColorScheme(this.meta);
}

UserSettingsState useUserSettings() {
  useOnPlatformBrightnessChange((previous, current) {
    userSettingsState._setModeFromSystem(
        systemMode: current == Brightness.dark ? ThemeMode.dark : ThemeMode.light);
  });

  useListenable(userSettingsState);

  return userSettingsState;
}

class UserSettingsState extends ChangeNotifier {
  late SharedPreferences _preferencesStore;
  ThemeMode _mode = ThemeMode.light;
  bool _showLivePrayers = true;
  bool _useHaptics = true;
  bool _useSystemMode = true;
  bool ready = false;

  Future<void> init() async {
    _preferencesStore = await SharedPreferences.getInstance();

    ready = true;

    _mode = _preferencesStore.getString('mode') == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _showLivePrayers = _preferencesStore.getBool('showLivePrayers') ?? true;
    _useSystemMode = _preferencesStore.getBool('useSystemMode') ?? true;
    _useHaptics = _preferencesStore.getBool('useHaptics') ?? true;

    _setModeFromSystem();
    notifyListeners();
  }

  ThemeMode get mode {
    return _mode;
  }

  bool get isSystemMode {
    return _useSystemMode;
  }

  bool get isLightMode {
    return _mode == ThemeMode.light;
  }

  set isLightMode(bool isLight) {
    _useSystemMode = false;
    _mode = isLight ? ThemeMode.light : ThemeMode.dark;

    print('_preferencesStore isLightMode');

    _preferencesStore.setBool('useSystemMode', _useSystemMode);
    _preferencesStore.setString('mode', _mode.name);

    notifyListeners();
  }

  bool get isDarkMode {
    return _mode == ThemeMode.dark;
  }

  set isDarkMode(bool isDark) {
    _useSystemMode = false;
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;

    print('_preferencesStore isDarkMode');

    _preferencesStore.setBool('useSystemMode', _useSystemMode);
    _preferencesStore.setString('mode', _mode.name);

    notifyListeners();
  }

  void setLightMode() {
    _useSystemMode = false;
    _mode = ThemeMode.light;

    print('_preferencesStore setLightMode');

    _preferencesStore.setBool('useSystemMode', _useSystemMode);
    _preferencesStore.setString('mode', _mode.name);

    notifyListeners();
  }

  void setDarkMode() {
    _useSystemMode = false;
    _mode = ThemeMode.dark;

    print('_preferencesStore setDarkMode');

    _preferencesStore.setBool('useSystemMode', _useSystemMode);
    _preferencesStore.setString('mode', _mode.name);

    notifyListeners();
  }

  void toggleMode() {
    _useSystemMode = false;
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    _preferencesStore.setBool('useSystemMode', _useSystemMode);
    _preferencesStore.setString('mode', _mode.name);

    notifyListeners();
  }

  set useSystemMode(bool useSystemMode) {
    _useSystemMode = useSystemMode;

    print('_preferencesStore useSystemMode');

    _preferencesStore.setBool('useSystemMode', _useSystemMode);

    if (_useSystemMode) {
      _setModeFromSystem();
    } else {
      notifyListeners();
    }
  }

  void _setModeFromSystem({ThemeMode? systemMode}) {
    if (_useSystemMode) {
      _mode = systemMode ??
          (PlatformDispatcher.instance.platformBrightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light);
      notifyListeners();
    }
  }

  set showLivePrayers(bool value) {
    _showLivePrayers = value;

    print('_preferencesStore showLivePrayers');

    _preferencesStore.setBool('showLivePrayers', _showLivePrayers);

    notifyListeners();
  }

  bool get showLivePrayers {
    return _showLivePrayers;
  }

  set useHaptics(bool value) {
    _useHaptics = value;

    print('_preferencesStore useHaptics');

    _preferencesStore.setBool('useHaptics', _useHaptics);

    notifyListeners();
  }

  bool get useHaptics {
    return _useHaptics;
  }

  void haptic (Future<void> Function() hapticFunction) {
    if (_useHaptics) {
      hapticFunction();
    }
  }
}

final userSettingsState = UserSettingsState();
