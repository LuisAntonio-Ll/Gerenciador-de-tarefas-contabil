import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static final primarySwatch = ValueNotifier<MaterialColor>(_defaultMaterialBlue);

  static MaterialColor get _defaultMaterialBlue => _materialColorFromKey('blue');

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('dark_mode') ?? false;
    final variant = prefs.getString('theme_variant') ?? 'blue';
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
      case 'purple':
      case 'deepPurple':
        return Colors.deepPurple;
      case 'orange':
        return Colors.orange;
      case 'blue':
      default:
        return const MaterialColor(
          0xFF0F4C81,
          <int, Color>{
            50: Color(0xFFEAF3FB),
            100: Color(0xFFCFE3F3),
            200: Color(0xFF9FC3E1),
            300: Color(0xFF6EA3CF),
            400: Color(0xFF3D84BE),
            500: Color(0xFF0F4C81),
            600: Color(0xFF0D4371),
            700: Color(0xFF0B3A60),
            800: Color(0xFF09314F),
            900: Color(0xFF07273E),
          },
        );
    }
  }

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
