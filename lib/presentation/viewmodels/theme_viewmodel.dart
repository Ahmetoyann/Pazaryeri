import 'package:flutter/material.dart';
import 'auth_service.dart';

class ThemeViewModel extends ChangeNotifier {
  int _themeModeIndex = 0; // 0: System, 1: Light, 2: Dark
  Color _seedColor = Colors.green;

  ThemeMode get themeMode {
    switch (_themeModeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int get themeModeIndex => _themeModeIndex;
  Color get seedColor => _seedColor;

  ThemeViewModel() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _themeModeIndex = await AuthService.instance.getThemeMode();
    final colorValue = await AuthService.instance.getThemeColor();
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(int mode) async {
    _themeModeIndex = mode;
    await AuthService.instance.updateThemeMode(mode);
    notifyListeners();
  }

  Future<void> changeSeedColor(Color color) async {
    _seedColor = color;
    await AuthService.instance.updateThemeColor(color.value);
    notifyListeners();
  }
}
