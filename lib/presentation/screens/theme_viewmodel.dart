import 'package:flutter/material.dart';
import '../screens/auth_service.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = true;
  Color _seedColor = Colors.green;

  bool get isDarkMode => _isDarkMode;
  Color get seedColor => _seedColor;

  ThemeViewModel() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _isDarkMode = await AuthService.instance.getThemeMode();
    final colorValue = await AuthService.instance.getThemeColor();
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    await AuthService.instance.updateThemeMode(isDark);
    notifyListeners();
  }

  Future<void> changeSeedColor(Color color) async {
    _seedColor = color;
    await AuthService.instance.updateThemeColor(color.value);
    notifyListeners();
  }
}
