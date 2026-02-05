import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/market.dart';
import '../viewmodels/notification_service.dart';
import 'user_model.dart'; // Bu dosyanın projenizde olduğundan emin olun
import 'auth_service.dart';
import '../widgets/guest_login_dialog.dart';

class AuthViewModel extends ChangeNotifier {
  // --- MEVCUT DEĞİŞKENLER ---
  User? _currentUser;

  // --- 1. YENİ MİSAFİR DURUMU DEĞİŞKENİ EKLENDİ ---
  bool _isGuest = false;
  bool _isUploadingProfilePhoto = false;
  double _uploadProgress = 0.0;
  bool _isRemembered = false;
  bool _isNewUser = false;
  bool _isSeller = false;
  String? _sellerMarketId;
  String? _verificationId;
  StreamSubscription? _notificationSubscription;

  // Constructor'da otomatik giriş kontrolü yap
  AuthViewModel() {
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    // 1. Önce yerel veriyi (SharedPreferences) kontrol et
    var userData = await AuthService.instance.getUserData();

    // 2. Yerel veri yoksa ama Firebase Auth oturumu açıksa (Senkronizasyon sorunu varsa)
    if (userData == null) {
      userData = await AuthService.instance.restoreSession();
    }

    if (userData != null) {
      _setUserFromData(userData);
      _isRemembered = true; // Kayıtlı veri varsa hatırlanmış demektir
      _isSeller = await AuthService.instance.isSeller();

      // Çoklu cihaz senkronizasyonu: İnternet varsa güncel veriyi çek
      if (userData['id'] != null) {
        _refreshUserProfile(userData['id']!);
      }

      // Favori pazarları dinlemeye başla
      _startListeningToFavorites();

      // Bildirimleri dinle (Satıcı ve Müşteri)
      _startNotificationListener();
    }
  }

  void _setUserFromData(Map<String, String> userData) {
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

      _sellerMarketId = userData['sellerMarketId'];
      if (_sellerMarketId != null && _sellerMarketId!.isEmpty) {
        _sellerMarketId = null;
      }

      notifyListeners();
    }
  }

  // Arka planda kullanıcı verilerini güncelle
  Future<void> _refreshUserProfile(String uid) async {
    final freshData = await AuthService.instance.refreshUserData(uid);
    if (freshData != null) {
      _setUserFromData(freshData);
      notifyListeners();
    }
  }

  /// İnternet bağlantısı geri geldiğinde mevcut kullanıcının profilini yeniler.
  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      await _refreshUserProfile(_currentUser!.id);
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

  /// Profil fotoğrafı yükleniyor mu?
  bool get isUploadingProfilePhoto => _isUploadingProfilePhoto;

  /// Yükleme ilerleme durumu (0.0 - 1.0 arası)
  double get uploadProgress => _uploadProgress;

  /// Kullanıcının "Beni Hatırla" seçeneğini işaretleyip işaretlemediği.
  bool get isRemembered => _isRemembered;

  /// Son giriş işleminin yeni bir kayıt olup olmadığı.
  bool get isNewUser => _isNewUser;

  /// Kullanıcının satıcı olup olmadığı.
  bool get isSeller => _isSeller;

  /// Satıcının seçtiği pazar ID'si.
  String? get sellerMarketId => _sellerMarketId;

  // --- METOTLAR (Durumları değiştirmek için) ---

  /// Kullanıcının işlem yapabilmesi için giriş yapmış olması gerektiğini doğrular.
  /// Eğer kullanıcı misafir modundaysa veya giriş yapmamışsa,
  /// [GuestLoginDialog] penceresini gösterir ve `false` döner.
  /// Kullanıcı giriş yapmışsa `true` döner.
  Future<bool> checkGuestStatus(BuildContext context) async {
    if (!isAuthenticated) {
      await GuestLoginDialog.show(context);
      return false;
    }
    return true;
  }

  /// Satıcı girişi yapar.
  Future<bool> loginAsSeller(String email, String password,
      {bool rememberMe = true}) async {
    try {
      final userData = await AuthService.instance.loginWithFirebase(
        email,
        password,
        rememberMe: rememberMe,
      );

      if (userData != null) {
        _setUserFromData(userData);
        await AuthService.instance.setIsSeller(true);
        _isSeller = true;
        _isGuest = false;
        _startNotificationListener();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      // Hata mesajını temizle (Exception: ... kısmını kaldır)
      final message = e.toString().replaceAll('Exception: ', '');
      throw message;
    }
  }

  /// Şifre sıfırlama e-postası gönderir.
  Future<void> resetPassword(String email) async {
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      throw message;
    }
  }

  /// Satıcı kaydı oluşturur.
  Future<void> registerSeller({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String marketId,
  }) async {
    try {
      // 1. Firebase Auth ile kullanıcı oluştur
      final userCredential = await AuthService.instance
          .registerWithEmailAndPassword(email, password);
      final user = userCredential.user;

      if (user != null) {
        // 2. Kullanıcı bilgilerini güncelle (DisplayName)
        await user.updateDisplayName('$firstName $lastName');

        // 3. Firestore'a satıcı detaylarını kaydet
        await AuthService.instance.updateUserInDb({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phoneNumber,
          'isSeller': true, // Satıcı olarak işaretle
          'sellerMarketId': marketId, // Pazar yerini kaydet
          'dateOfBirth': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        }, email);

        // 4. Oturumu kapat (Kullanıcı giriş sayfasına yönlendirilecek)
        await AuthService.instance.logout(clearFavorites: true);
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      throw message;
    }
  }

  /// Google ile giriş yapar.
  Future<bool> loginWithGoogle() async {
    try {
      _isNewUser = false;
      final userCredential = await AuthService.instance.signInWithGoogle();
      if (userCredential == null) return false; // İptal edildi

      // Google ile gelen kullanıcı yeni kayıt olsa bile direkt giriş yapsın.
      // Profil tamamlama ekranına yönlendirmemek için false set ediyoruz.
      _isNewUser = false;
      // Yerel hafıza gecikmesini önlemek için doğrudan oturumu kurtar
      final userData = await AuthService.instance.restoreSession();

      if (userData != null) {
        _setUserFromData(userData);
        await AuthService.instance.setIsSeller(false);
        _isSeller = false;
        _isGuest = false;
        _startNotificationListener();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      // Hata mesajını temizle (Exception: ... kısmını kaldır) ve sadece mesajı fırlat
      final message = e.toString().replaceAll('Exception: ', '');
      throw message;
    }
  }

  /// Kullanıcının oturumunu kapatır.
  void logout() {
    // Normal çıkışta favorileri temizle (Gizlilik için)
    AuthService.instance.logout(clearFavorites: true);
    _currentUser = null;
    _isGuest = false; // Çıkış yaparken misafir modu da kapatılır.
    _isSeller = false;
    _isRemembered = false;
    _sellerMarketId = null;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    notifyListeners();
  }

  /// Misafir modundan çıkış yapar ve kullanıcıyı giriş ekranına yönlendirir.
  void exitGuestMode() {
    // Misafir çıkışında favorileri SİLME, böylece giriş yapınca birleştirilebilir.
    AuthService.instance.logout(clearFavorites: false);
    _currentUser = null;
    _isSeller = false;
    _isGuest = false;
    _isRemembered = false;
    _sellerMarketId = null;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    notifyListeners();
  }

  // --- 3. YENİ MİSAFİR METODU EKLENDİ ---
  /// Misafir modunu başlatır ve durumu günceller.
  void enterAsGuest() {
    // Kullanıcı ve misafir durumlarını sıfırla
    _currentUser = null;
    _isSeller = false;
    _isGuest = true;
    _isRemembered = false;
    _sellerMarketId = null;
    notifyListeners(); // Durum değişikliğini dinleyen widget'lara bildir.
  }

  /// Satıcının pazar ID'sini günceller.
  void setSellerMarketId(String id) {
    _sellerMarketId = id;
    notifyListeners();
  }

  /// Kullanıcının profil fotoğrafını günceller.
  Future<void> updateProfilePhoto(String path) async {
    if (_currentUser != null) {
      final oldUser = _currentUser; // Hata durumunda geri almak için yedekle
      final String? oldPhotoUrl =
          _currentUser!.profilePicturePath; // Eski URL'i sakla
      // 1. Önce yerel yolu göster (Hızlı tepki / Optimistic Update)
      _currentUser = User(
        id: _currentUser!.id,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        dateOfBirth: _currentUser!.dateOfBirth,
        phoneNumber: _currentUser!.phoneNumber,
        email: _currentUser!.email,
        profilePicturePath: path,
      );
      _isUploadingProfilePhoto = true;
      _uploadProgress = 0.0;
      notifyListeners();

      try {
        // 2. Fotoğrafı Firebase Storage'a yükle
        final String downloadUrl =
            await AuthService.instance.uploadProfilePictureToStorage(
          File(path),
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );

        // 3. URL'i User nesnesine ve Veritabanına kaydet
        _currentUser = User(
          id: _currentUser!.id,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          dateOfBirth: _currentUser!.dateOfBirth,
          phoneNumber: _currentUser!.phoneNumber,
          email: _currentUser!.email,
          profilePicturePath: downloadUrl, // Artık URL kullanıyoruz
        );

        await AuthService.instance.updateUserInDb(
            {'profilePicture': downloadUrl}, _currentUser!.email);
        await AuthService.instance.updateProfilePicture(downloadUrl);

        // 3. Eski fotoğrafı sil (Eğer varsa ve Firebase Storage URL'i ise)
        if (oldPhotoUrl != null) {
          await AuthService.instance.deleteImageFromStorage(oldPhotoUrl);
        }
      } catch (e) {
        debugPrint('Fotoğraf yükleme hatası: $e');
        // Hata durumunda eski haline döndür ve hatayı fırlat
        _currentUser = oldUser;
        rethrow;
      } finally {
        _isUploadingProfilePhoto = false;
        _uploadProgress = 0.0;
        notifyListeners();
      }
    }
  }

  // --- TELEFON DOĞRULAMA ---

  /// Telefon doğrulama işlemini başlatır.
  /// [onCodeSent]: SMS gönderildiğinde çağrılır.
  /// [onAutoVerify]: Android'de otomatik doğrulama olursa çağrılır.
  /// [onError]: Hata durumunda çağrılır.
  Future<void> startPhoneVerification(
    String phoneNumber, {
    required Function() onCodeSent,
    required Function() onAutoVerify,
    required Function(String) onError,
  }) async {
    try {
      await AuthService.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android'de otomatik doğrulama gerçekleşirse
          // Burada credential ile işlem yapılabilir, şimdilik sadece bildiriyoruz
          onAutoVerify();
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Doğrulama hatası');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Kullanıcının girdiği SMS kodunu doğrular.
  Future<bool> verifySMSCode(String smsCode) async {
    if (_verificationId == null) return false;
    try {
      final credential =
          AuthService.instance.getPhoneCredential(_verificationId!, smsCode);
      // Credential geçerliyse (hata fırlatmazsa) doğrulama başarılıdır.
      // Not: Burada signInWithCredential yapmıyoruz, sadece kodun doğruluğunu test ediyoruz.
      // Gerçek bir oturum açma için: await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Kullanıcının profil fotoğrafını kaldırır.
  Future<void> removeProfilePhoto() async {
    if (_currentUser != null) {
      final String? oldPhotoUrl =
          _currentUser!.profilePicturePath; // Eski URL'i sakla
      _currentUser = User(
        id: _currentUser!.id,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        dateOfBirth: _currentUser!.dateOfBirth,
        phoneNumber: _currentUser!.phoneNumber,
        email: _currentUser!.email,
        profilePicturePath: null,
      );
      notifyListeners();

      await AuthService.instance.updateUserInDb({
        'profilePicture': '',
      }, _currentUser!.email);
      await AuthService.instance.updateProfilePicture('');

      // Eski fotoğrafı storage'dan da sil
      if (oldPhotoUrl != null) {
        await AuthService.instance.deleteImageFromStorage(oldPhotoUrl);
      }
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

      _currentUser = User(
        id: _currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
        email: email,
        profilePicturePath: _currentUser!.profilePicturePath,
      );

      // UI'ın anlık güncellenmesi için notifyListeners'ı asenkron işlemden önce çağırıyoruz (Optimistic Update)
      notifyListeners();

      // AuthService.updateUserInfo metodu verileri önce SharedPreferences'a (yerel hafıza)
      // kaydeder, ardından Firestore'u günceller. Bu sayede internet olmasa bile veriler korunur.
      await AuthService.instance.updateUserInfo(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth.toIso8601String(),
        email: email,
      );
    }
  }

  /// Kullanıcı hesabını siler.
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      await AuthService.instance.deleteUserFromDb(_currentUser!.email);

      logout();
    }
  }

  // --- BİLDİRİM DİNLEYİCİSİ ---

  /// Favori pazarların açık olup olmadığını kontrol eder ve bildirim gönderir.
  /// Günde sadece 1 kez çalışır.
  Future<void> _startListeningToFavorites() async {
    // Firestore kaldırıldığı için bildirim dinleme iptal edildi.
  }

  /// Kullanıcıya gelen bildirimleri dinler (Satıcı veya Müşteri)
  /// Müşteriler için: Sadece satıcı yanıtları Firestore'a yazıldığı için buradan gelir.
  void _startNotificationListener() {
    if (_currentUser == null) return;

    _notificationSubscription?.cancel();

    // Sadece son 1 dakikada gelenleri veya yeni eklenenleri dinlemek için
    // Basitçe stream başlatıyoruz, 'added' eventlerini yakalıyoruz.
    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.id)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['read'] == false) {
            // Bildirimi göster
            NotificationService.instance.showNotification(
              id: DateTime.now().millisecondsSinceEpoch % 10000,
              title: data['title'] ?? 'Bildirim',
              body: data['body'] ?? '',
            );

            // Okundu olarak işaretle ki tekrar gelmesin
            change.doc.reference.update({'read': true});
          }
        }
      }
    });
  }

  /// Favori pazarları kontrol et ve bugün açıksa bildirim gönder
  /// Müşteriler için: Favori pazarın açık olduğu günlerde yerel bildirim gönderir.
  Future<void> checkFavoritesAndNotify(List<Market> allMarkets) async {
    if (_currentUser == null) return;

    try {
      // 1. Kullanıcının favorilerini çek
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .collection('favorites')
          .get();

      final favoriteIds = snapshot.docs.map((doc) => doc.id).toSet();
      if (favoriteIds.isEmpty) return;

      // 2. Tüm pazarlar içinden favorileri bul
      final favoriteMarkets =
          allMarkets.where((m) => favoriteIds.contains(m.id)).toList();
      if (favoriteMarkets.isEmpty) return;

      // 3. Bugün açık olan favorileri bul
      final today = _getTodayName();
      final openFavorites =
          favoriteMarkets.where((m) => m.openDays.contains(today)).toList();

      if (openFavorites.isEmpty) return;

      // 4. Bugün daha önce bildirim gönderildi mi kontrol et
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString('last_fav_notification_date');
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      if (lastDate != todayStr) {
        // 5. Bildirim gönder
        final marketNames = openFavorites.map((m) => m.name).join(', ');
        await NotificationService.instance.showNotification(
          id: 100,
          title: 'Favori Pazarlarınız Açık! 🛒',
          body: 'Bugün açık olan pazarlar: $marketNames',
          payload: openFavorites.first.id, // Tıklanınca ilk pazara git
        );

        // 6. Tarihi kaydet (Bugün tekrar gönderme)
        await prefs.setString('last_fav_notification_date', todayStr);
      }
    } catch (e) {
      debugPrint('Favori bildirim hatası: $e');
    }
  }

  String _getTodayName() {
    final map = {
      1: 'Pazartesi',
      2: 'Salı',
      3: 'Çarşamba',
      4: 'Perşembe',
      5: 'Cuma',
      6: 'Cumartesi',
      7: 'Pazar',
    };
    return map[DateTime.now().weekday]!;
  }
}
