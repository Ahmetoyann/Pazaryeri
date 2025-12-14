import 'package:flutter/material.dart';
import '../screens/auth_service.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeViewModel() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _isDarkMode = await AuthService.instance.getThemeMode();
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    await AuthService.instance.updateThemeMode(isDark);
    notifyListeners();
  }
}
