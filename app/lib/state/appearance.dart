// Light / dark / system, as the POC had it (Color Scheme in its settings).
// Device-local and read before the first frame, so the app opens in the
// right theme. Dark is the default: it's the primary design (app-brief §0).

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/local/preferences.dart';

/// Overridden at startup with [DevicePreferences]; tests get memory.
final preferencesProvider = Provider<Preferences>((_) => MemoryPreferences());

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'appearance';

  @override
  ThemeMode build() {
    final stored = ref.watch(preferencesProvider).getString(_key);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.dark;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(preferencesProvider).setString(_key, mode.name);
  }
}
