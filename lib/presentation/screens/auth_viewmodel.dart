import 'dart:math';
import 'package:flutter/material.dart';
import 'user_model.dart'; // Bu dosyanın projenizde olduğundan emin olun
import 'auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  // --- MEVCUT DEĞİŞKENLER ---
  User? _currentUser;

  // --- 1. YENİ MİSAFİR DURUMU DEĞİŞKENİ EKLENDİ ---
  bool _isGuest = false;
  String? _verificationCode; // Şifre sıfırlama için geçici kod

  // Constructor'da otomatik giriş kontrolü yap
  AuthViewModel() {
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final userData = await AuthService.instance.getUserData();
    if (userData != null && userData['email']!.isNotEmpty) {
      _currentUser = User(
        id: userData['id']!,
        firstName: userData['firstName']!,
        lastName: userData['lastName']!,
        dateOfBirth:
            DateTime.tryParse(userData['dateOfBirth']!) ?? DateTime.now(),
        phoneNumber: userData['phoneNumber']!,
        email: userData['email']!,
        profilePicturePath: (userData['profilePicture'] != null &&
                userData['profilePicture']!.isNotEmpty)
            ? userData['profilePicture']
            : null,
      );
      _isGuest = false;
      notifyListeners();
    }
  }

  // --- GETTER'LAR (Durumları okumak için) ---

  /// O anki giriş yapmış kullanıcıyı döndürür.
  User? get currentUser => _currentUser;

  /// Kullanıcının giriş yapıp yapmadığını kontrol eder.
  /// Misafir modunda ise giriş yapmamış sayılır.
  bool get isAuthenticated => _currentUser != null;

  /// Kullanıcının misafir modunda olup olmadığını kontrol eder.
  bool get isGuest => _isGuest;

  // --- METOTLAR (Durumları değiştirmek için) ---

  /// Bir kullanıcıyı e-posta ve şifre ile sisteme dahil eder.
  Future<bool> login(String email, String password) async {
    try {
      await AuthService.instance.loginWithFirebase(email, password);

      // Giriş başarılı, kullanıcı verilerini güncelle
      await _checkAutoLogin();

      // Giriş başarılı olduğunda misafir modunu kapat
      _isGuest = false;
      notifyListeners();
      return true;
    } catch (e) {
      rethrow; // Hatayı UI'a fırlat
    }
  }

  /// Google ile giriş yapar.
  Future<bool> loginWithGoogle() async {
    try {
      await AuthService.instance.signInWithGoogle();
      await _checkAutoLogin();

      if (_currentUser != null) {
        _isGuest = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Yeni bir kullanıcı kaydı oluşturur.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phoneNumber,
    required String email,
    required String password,
    String? profilePicturePath,
  }) async {
    try {
      await AuthService.instance.registerUserInDb(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth.toIso8601String(),
        profilePicturePath: profilePicturePath,
      );
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Kullanıcının şifresini sıfırlar (günceller).
  Future<bool> resetPassword(String email, String newPassword) async {
    // Firebase'de şifre sıfırlama e-posta ile yapılır, doğrudan şifre set edilmez (güvenlik gereği).
    // Ancak giriş yapmış bir kullanıcı şifresini değiştirebilir.
    // Burada "Şifremi Unuttum" senaryosu için e-posta gönderimini tetikleyebiliriz.
    await AuthService.instance.sendPasswordResetEmail(email);
    return true;
  }

  /// Şifre sıfırlama için doğrulama kodu gönderir (Simülasyon).
  Future<bool> sendVerificationCode(String email) async {
    try {
      // Firebase'in kendi şifre sıfırlama mekanizmasını kullanıyoruz
      await AuthService.instance.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      throw Exception('E-posta gönderilemedi: $e');
    }
  }

  /// Girilen kodun doğruluğunu kontrol eder.
  bool verifyCode(String code) {
    // Firebase link ile çalıştığı için kod doğrulamaya gerek kalmaz,
    // ancak UI akışını bozmamak için true dönebiliriz veya bu adımı UI'dan kaldırabilirsiniz.
    return true;
  }

  /// Kullanıcının oturumunu kapatır.
  void logout() {
    AuthService.instance.logout(); // Hafızadan sil
    _currentUser = null;
    _isGuest = false; // Çıkış yaparken misafir modu da kapatılır.
    notifyListeners();
  }

  // --- 3. YENİ MİSAFİR METODU EKLENDİ ---
  /// Misafir modunu başlatır ve durumu günceller.
  void enterAsGuest() {
    // Kullanıcı ve misafir durumlarını sıfırla
    _currentUser = null;
    _isGuest = true;
    notifyListeners(); // Durum değişikliğini dinleyen widget'lara bildir.
  }

  /// Kullanıcının profil fotoğrafını günceller.
  Future<void> updateProfilePhoto(String path) async {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        dateOfBirth: _currentUser!.dateOfBirth,
        phoneNumber: _currentUser!.phoneNumber,
        email: _currentUser!.email,
        profilePicturePath: path,
      );
      await AuthService.instance.updateUserInDb({
        'profilePicture': path,
      }, _currentUser!.email);
      await AuthService.instance.updateProfilePicture(path);
      notifyListeners();
    }
  }

  /// Kullanıcının profil fotoğrafını kaldırır.
  Future<void> removeProfilePhoto() async {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        dateOfBirth: _currentUser!.dateOfBirth,
        phoneNumber: _currentUser!.phoneNumber,
        email: _currentUser!.email,
        profilePicturePath: null,
      );
      await AuthService.instance.updateUserInDb({
        'profilePicture': '',
      }, _currentUser!.email);
      await AuthService.instance.updateProfilePicture('');
      notifyListeners();
    }
  }

  /// Kullanıcının metin tabanlı bilgilerini günceller.
  Future<void> updateUserInfo({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String email,
    String? newPassword,
  }) async {
    if (_currentUser != null) {
      String currentEmail = _currentUser!.email;
      bool emailChanged = currentEmail != email;

      // Not: Firebase'de e-posta değiştirmek için yeniden kimlik doğrulama gerekir.
      // Bu örnekte sadece Firestore verisini güncelliyoruz.

      Map<String, dynamic> dbUpdates = {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth.toIso8601String(),
      };
      // Şifre güncelleme Firebase Auth üzerinden yapılmalıdır (updatePassword).

      _currentUser = User(
        id: _currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
        email: email,
        profilePicturePath: _currentUser!.profilePicturePath,
      );
      await AuthService.instance.updateUserInDb(dbUpdates, email);
      await AuthService.instance.updateUserInfo(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth.toIso8601String(),
        email: email,
      );
      notifyListeners();
    }
  }

  /// Kullanıcı hesabını siler.
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      await AuthService.instance.deleteUserFromDb(_currentUser!.email);

      logout();
    }
  }
}
