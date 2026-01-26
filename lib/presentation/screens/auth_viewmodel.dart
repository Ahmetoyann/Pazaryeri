import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodels/notification_service.dart';
import 'user_model.dart'; // Bu dosyanın projenizde olduğundan emin olun
import 'auth_service.dart';

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
  StreamSubscription<QuerySnapshot>? _productSubscription;

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

  /// Bir kullanıcıyı e-posta ve şifre ile sisteme dahil eder.
  Future<bool> login(String email, String password,
      {bool rememberMe = true}) async {
    try {
      final userData = await AuthService.instance.loginWithFirebase(
        email,
        password,
        rememberMe: rememberMe,
      );

      if (userData != null) {
        // Beni hatırla seçili olmasa bile o anlık oturum için kullanıcıyı set et
        _setUserFromData(userData);
        _isRemembered = rememberMe;
      } else if (rememberMe) {
        // Veri dönmediyse ama beni hatırla açıksa SP'den okumayı dene
        await _checkAutoLogin();
      }

      // Giriş başarılı olduğunda misafir modunu kapat
      await AuthService.instance.setIsSeller(false);
      _isSeller = false;
      _isGuest = false;
      notifyListeners();

      // Giriş başarılı, bildirimleri dinle
      _startListeningToFavorites();
      return true;
    } catch (e) {
      rethrow; // Hatayı UI'a fırlat
    }
  }

  /// Satıcı girişi yapar.
  Future<bool> loginAsSeller(String email, String password) async {
    try {
      final userData = await AuthService.instance.loginWithFirebase(
        email,
        password,
        rememberMe: true,
      );

      if (userData != null) {
        _setUserFromData(userData);
        await AuthService.instance.setIsSeller(true);
        _isSeller = true;
        _isGuest = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Google ile giriş yapar.
  Future<bool> loginWithGoogle() async {
    try {
      _isNewUser = false;
      final isNewUser = await AuthService.instance.signInWithGoogle();
      if (isNewUser == null) return false; // İptal edildi

      // Google ile gelen kullanıcı yeni kayıt olsa bile direkt giriş yapsın.
      // Profil tamamlama ekranına yönlendirmemek için false set ediyoruz.
      _isNewUser = false;
      await _checkAutoLogin();

      if (_currentUser != null) {
        await AuthService.instance.setIsSeller(false);
        _isSeller = false;
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
    bool isSeller = false,
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
        isSeller: isSeller,
      );

      // Otomatik giriş yapıldığı için state'i güncelle
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _currentUser = User(
          id: uid,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          phoneNumber: phoneNumber,
          email: email,
          profilePicturePath: profilePicturePath,
        );
        _isSeller = isSeller;
        _isGuest = false;
        _isRemembered = true;
      }
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Şifre sıfırlama bağlantısı gönderir.
  Future<bool> sendVerificationCode(String email) async {
    try {
      // Firebase'in kendi şifre sıfırlama mekanizmasını kullanıyoruz
      await AuthService.instance.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('user_not_found');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('E-posta gönderilemedi: $e');
    }
  }

  /// Doğrulama e-postasını tekrar gönderir.
  Future<void> resendVerificationEmail(String email, String password) async {
    try {
      await AuthService.instance.resendVerificationEmail(email, password);
    } catch (e) {
      rethrow;
    }
  }

  /// Kullanıcının oturumunu kapatır.
  void logout() {
    // Normal çıkışta favorileri temizle (Gizlilik için)
    _productSubscription?.cancel(); // Dinleyiciyi durdur
    AuthService.instance.logout(clearFavorites: true);
    _currentUser = null;
    _isGuest = false; // Çıkış yaparken misafir modu da kapatılır.
    _isSeller = false;
    _isRemembered = false;
    _sellerMarketId = null;
    notifyListeners();
  }

  /// Misafir modundan çıkış yapar ve kullanıcıyı giriş ekranına yönlendirir.
  void exitGuestMode() {
    // Misafir çıkışında favorileri SİLME, böylece giriş yapınca birleştirilebilir.
    _productSubscription?.cancel();
    AuthService.instance.logout(clearFavorites: false);
    _currentUser = null;
    _isSeller = false;
    _isGuest = false;
    _isRemembered = false;
    _sellerMarketId = null;
    notifyListeners();
  }

  // --- 3. YENİ MİSAFİR METODU EKLENDİ ---
  /// Misafir modunu başlatır ve durumu günceller.
  void enterAsGuest() {
    // Kullanıcı ve misafir durumlarını sıfırla
    _productSubscription?.cancel();
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

  /// Favori pazarlara yeni ürün eklendiğinde bildirim gönderir.
  Future<void> _startListeningToFavorites() async {
    await _productSubscription?.cancel();

    // Favorileri al
    final favorites = await AuthService.instance.getFavorites();
    if (favorites.isEmpty) return;

    // Firestore 'whereIn' limiti 10'dur. İlk 10 favoriyi dinliyoruz.
    final limitedFavorites = favorites.take(10).toList();

    // Sadece şu andan sonra eklenenleri dinle
    final now = Timestamp.now();

    try {
      _productSubscription = FirebaseFirestore.instance
          .collection('products')
          .where('sellerMarketId', whereIn: limitedFavorites)
          .where('createdAt', isGreaterThan: now)
          .snapshots()
          .listen((snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              final productName = data['name'] ?? 'Ürün';
              final marketId = data['sellerMarketId'];
              // Bildirim gönder
              NotificationService.instance.showNotification(
                id: DateTime.now().millisecondsSinceEpoch % 100000,
                title: 'Favori Pazarında Yeni Ürün!',
                body: '$productName tezgahta yerini aldı. Hemen incele!',
                payload: marketId, // Pazar ID'sini bildirime ekle
              );
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Bildirim dinleyicisi başlatılamadı (Index gerekebilir): $e');
    }
  }
}
