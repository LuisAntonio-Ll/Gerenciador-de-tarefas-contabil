import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static final primarySwatch = ValueNotifier<MaterialColor>(Colors.indigo);

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('dark_mode') ?? false;
    final variant = prefs.getString('theme_variant') ?? 'indigo';
    themeMode.value = darkMode ? ThemeMode.dark : ThemeMode.light;
    primarySwatch.value = _materialColorFromKey(variant);
  }

  static Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
  }

  static Future<void> setThemeVariant(String key) async {
    primarySwatch.value = _materialColorFromKey(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_variant', key);
  }

  static MaterialColor _materialColorFromKey(String key) {
    switch (key) {
      case 'green':
        return Colors.green;
      case 'teal':
        return Colors.teal;
      case 'deepPurple':
        return Colors.deepPurple;
      case 'indigo':
      default:
        return Colors.indigo;
    }
  }

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
