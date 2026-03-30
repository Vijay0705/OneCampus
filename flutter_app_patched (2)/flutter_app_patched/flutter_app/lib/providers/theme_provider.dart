import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Label for the current selection (used by UI)
  String get label {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Load persisted theme from secure storage on app startup.
  Future<void> loadTheme() async {
    final stored = await _storage.read(key: _key);
    _themeMode = _fromString(stored);
    notifyListeners();
  }

  /// Called when the user picks a new theme.
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.write(key: _key, value: _toString(mode));
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────
  static ThemeMode _fromString(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
