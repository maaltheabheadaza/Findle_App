import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
} 