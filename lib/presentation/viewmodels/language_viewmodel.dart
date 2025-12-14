import 'package:flutter/material.dart';
import '../screens/auth_service.dart';
import 'app_strings.dart';

class LanguageViewModel extends ChangeNotifier {
  String _currentLanguage = 'tr';

  String get currentLanguage => _currentLanguage;

  LanguageViewModel() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    _currentLanguage = await AuthService.instance.getLanguage();
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;
    _currentLanguage = languageCode;
    await AuthService.instance.updateLanguage(languageCode);
    notifyListeners();
  }

  // Arayüzden kolayca çeviri almak için yardımcı metod
  String translate(String key) => AppStrings.getString(key, _currentLanguage);
}
