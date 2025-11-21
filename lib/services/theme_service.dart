import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple theme service using a ValueNotifier and SharedPreferences.
/// Call `ThemeService.init()` before running the app.
class ThemeService {
  static final ValueNotifier<ThemeMode> modeNotifier = ValueNotifier(ThemeMode.light);

  static const _prefKey = 'themeMode';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored == 'dark') {
      modeNotifier.value = ThemeMode.dark;
    } else if (stored == 'system') {
      modeNotifier.value = ThemeMode.system;
    } else {
      modeNotifier.value = ThemeMode.light;
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    modeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.system ? 'system' : 'light');
  }
}
