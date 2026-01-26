import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._init();
  static AuthService get instance => _instance;

  AuthService._init();

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyFirstName = 'firstName';
  static const String _keyLastName = 'lastName';
  static const String _keyPhoneNumber = 'phoneNumber';
  static const String _keyDateOfBirth = 'dateOfBirth';
  static const String _keyProfilePicture = 'profilePicture';
  static const String _keyThemeMode = 'themeMode';
  static const String _keyThemeColor = 'themeColor';
  static const String _keyLanguage = 'language';
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keyFavorites = 'favorite_markets';
  static const String _keyReviews = 'market_reviews';
  static const String _keyOnboardingSeen = 'onboarding_seen';
  static const String _keyIsSeller = 'is_seller';
  static const String _keyProductReviews = 'product_reviews';
  static const String _keyFavoriteSellers = 'favorite_sellers';
  static const String _keySellerMarketId = 'seller_market_id';

  // Mevcut kullanıcı ID'sini almak için yardımcı getter
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // --- FIREBASE AUTHENTICATION ---

  /// Firebase ile giriş yap ve kullanıcı verilerini Firestore'dan çekip yerel hafızaya al.
  Future<Map<String, String>?> loginWithFirebase(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    // 0. Önce yerel favorileri (Misafir modunda eklenenler) al
    final prefs = await SharedPreferences.getInstance();
    final List<String> localFavorites =
        prefs.getStringList(_keyFavorites) ?? [];

    // 1. Firebase Auth ile giriş
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) {
      throw Exception('Giriş başarısız: Kullanıcı bilgisi alınamadı.');
    }

    // 2. Firestore'dan kullanıcı detaylarını çek
    final uid = userCredential.user!.uid;
    DocumentSnapshot<Map<String, dynamic>>? docSnapshot;

    try {
      docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        docSnapshot = null; // Sunucuya erişilemedi, offline modda devam et
      } else {
        rethrow;
      }
    }

    if (docSnapshot != null && docSnapshot.exists) {
      final data = docSnapshot.data()!;

      // --- FAVORİLERİ BİRLEŞTİRME VE SENKRONİZASYON ---
      List<String> remoteFavorites = [];
      if (data['favorites'] != null) {
        remoteFavorites = List<String>.from(data['favorites']);
      }

      // Yerel ve uzak favorileri birleştir (Set kullanarak tekrarı önle)
      final Set<String> mergedFavorites = {
        ...localFavorites,
        ...remoteFavorites
      };
      final List<String> finalFavorites = mergedFavorites.toList();

      // Eğer yerel favoriler eklendiyse Firestore'u güncelle
      if (finalFavorites.length > remoteFavorites.length) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'favorites': finalFavorites,
        });
      }
      // Yerel hafızayı güncel birleşmiş favorilerle yenile
      await prefs.setStringList(_keyFavorites, finalFavorites);
      // ------------------------------------------------

      // Tarih alanı kontrolü (Timestamp veya String olabilir)
      String dob = '';
      if (data['dateOfBirth'] is Timestamp) {
        dob = (data['dateOfBirth'] as Timestamp).toDate().toIso8601String();
      } else {
        dob = (data['dateOfBirth'] ?? '').toString();
      }

      // Veri haritasını hazırla
      final userDataMap = {
        'id': uid,
        'email': email,
        'firstName': (data['firstName'] ?? '').toString(),
        'lastName': (data['lastName'] ?? '').toString(),
        'phoneNumber': (data['phoneNumber'] ?? '').toString(),
        'dateOfBirth': dob,
        'profilePicture': (data['profilePicture'] ?? '').toString(),
        'sellerMarketId': (data['sellerMarketId'] ?? '').toString(),
      };

      // 3. Eğer "Beni Hatırla" seçiliyse Verileri SharedPreferences'a kaydet
      if (rememberMe) {
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, userDataMap['id']!);
        await prefs.setString(_keyUserEmail, userDataMap['email']!);
        await prefs.setString(_keyFirstName, userDataMap['firstName']!);
        await prefs.setString(_keyLastName, userDataMap['lastName']!);
        await prefs.setString(_keyPhoneNumber, userDataMap['phoneNumber']!);
        await prefs.setString(_keyDateOfBirth, userDataMap['dateOfBirth']!);
        await prefs.setString(
            _keyProfilePicture, userDataMap['profilePicture']!);
        await prefs.setString(
            _keySellerMarketId, userDataMap['sellerMarketId']!);
      }
      return userDataMap;
    } else if (docSnapshot != null && !docSnapshot.exists) {
      // Firestore'da kullanıcı verisi yoksa (örn: kayıt sırasında hata oluştuysa veya farklı cihaz senkronizasyonu),
      // kaydı şimdi oluşturarak giriş yapmaya izin ver (Self-healing).
      final user = userCredential.user!;
      final now = DateTime.now().toIso8601String();
      final newData = {
        'id': uid,
        'email': email,
        'firstName': '',
        'lastName': '',
        'phoneNumber': '',
        'dateOfBirth': now,
        'profilePicture': null,
        'createdAt': FieldValue.serverTimestamp(),
        'favorites':
            localFavorites, // Yeni kullanıcıya misafir favorilerini ekle
        'sellerMarketId': '',
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newData);

      final userDataMap = {
        'id': uid,
        'email': email,
        'firstName': '',
        'lastName': '',
        'phoneNumber': '',
        'dateOfBirth': now,
        'profilePicture': '',
        'sellerMarketId': '',
      };

      if (rememberMe) {
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, uid);
        await prefs.setString(_keyUserEmail, email);
        await prefs.setString(_keyFirstName, '');
        await prefs.setString(_keyLastName, '');
        await prefs.setString(_keyPhoneNumber, '');
        await prefs.setString(_keyDateOfBirth, now);
        await prefs.setString(_keySellerMarketId, '');
      }
      return userDataMap;
    } else {
      // docSnapshot == null: Firestore erişim hatası (Offline/Unavailable)
      // Kullanıcıyı engellemek yerine Auth bilgileriyle devam et.
      final userDataMap = {
        'id': uid,
        'email': email,
        'firstName': '', // Profil yüklenemediği için boş geçiyoruz
        'lastName': '',
        'phoneNumber': '',
        'dateOfBirth': '',
        'profilePicture': '',
        'sellerMarketId': '',
      };
      if (rememberMe) {
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, uid);
        await prefs.setString(_keyUserEmail, email);
      }
      return userDataMap;
    }
  }

  /// Doğrulama e-postasını tekrar gönder
  Future<void> resendVerificationEmail(String email, String password) async {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null && !userCredential.user!.emailVerified) {
      await userCredential.user!.sendEmailVerification();
    }
    await FirebaseAuth.instance.signOut();
  }

  /// Google ile giriş yap
  Future<bool?> signInWithGoogle() async {
    try {
      // 0. Önce yerel favorileri (Misafir modunda eklenenler) al
      final prefs = await SharedPreferences.getInstance();
      final List<String> localFavorites =
          prefs.getStringList(_keyFavorites) ?? [];

      // 1. Google Sign-In akışını başlat
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // Kullanıcı iptal etti
        return null;
      }

      // 2. Kimlik doğrulama detaylarını al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Yeni bir kimlik bilgisi oluştur
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase ile giriş yap
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final uid = user.uid;
        final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final docSnapshot = await docRef.get();

        Map<String, dynamic> data;
        bool isNewUser = false;

        if (docSnapshot.exists) {
          data = docSnapshot.data()!;

          // --- FAVORİLERİ BİRLEŞTİRME VE SENKRONİZASYON ---
          List<String> remoteFavorites = [];
          if (data['favorites'] != null) {
            remoteFavorites = List<String>.from(data['favorites']);
          }

          final Set<String> mergedFavorites = {
            ...localFavorites,
            ...remoteFavorites
          };
          final List<String> finalFavorites = mergedFavorites.toList();

          if (finalFavorites.length > remoteFavorites.length) {
            await docRef.update({'favorites': finalFavorites});
          }
          await prefs.setStringList(_keyFavorites, finalFavorites);
          // ------------------------------------------------
        } else {
          isNewUser = true;
          // Yeni kullanıcı oluştur (İsim soyisim ayrıştırma)
          String firstName = '';
          String lastName = '';
          if (googleUser.displayName != null) {
            final parts = googleUser.displayName!.split(' ');
            if (parts.isNotEmpty) {
              firstName = parts.first;
              if (parts.length > 1) {
                lastName = parts.sublist(1).join(' ');
              }
            }
          }

          data = {
            'id': uid,
            'email': user.email ?? '',
            'firstName': firstName,
            'lastName': lastName,
            'phoneNumber': '',
            'dateOfBirth': DateTime.now().toIso8601String(),
            'profilePicture': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'favorites':
                localFavorites, // Yeni kullanıcıya misafir favorilerini ekle
            'sellerMarketId': '',
          };
          await docRef.set(data);
        }

        // 5. Verileri SharedPreferences'a kaydet
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, uid);
        await prefs.setString(_keyUserEmail, user.email ?? '');
        // Veri tiplerini garantiye al
        await prefs.setString(
            _keyFirstName, (data['firstName'] ?? '').toString());
        await prefs.setString(
            _keyLastName, (data['lastName'] ?? '').toString());
        await prefs.setString(
            _keyPhoneNumber, (data['phoneNumber'] ?? '').toString());

        String dob = '';
        if (data['dateOfBirth'] is Timestamp) {
          dob = (data['dateOfBirth'] as Timestamp).toDate().toIso8601String();
        } else {
          dob = (data['dateOfBirth'] ?? '').toString();
        }
        await prefs.setString(_keyDateOfBirth, dob);

        if (data['profilePicture'] != null) {
          await prefs.setString(
              _keyProfilePicture, data['profilePicture'].toString());
        }
        if (data['sellerMarketId'] != null) {
          await prefs.setString(
              _keySellerMarketId, data['sellerMarketId'].toString());
        }
        return isNewUser;
      }
      return null;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed') {
        throw Exception(
            'Google girişi yapılamadı. Lütfen Firebase konsolunda SHA-1 parmak izinin ekli olduğundan emin olun.');
      }
      throw Exception('Google giriş hatası: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('Google ile giriş yapılırken bir hata oluştu: $e');
    }
  }

  /// Firebase şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    // Standart şifre sıfırlama e-postası (Link tarayıcıda açılır)
    // Not: Deep link (uygulama içi yönlendirme) ayarları Firebase konsolunda
    // tam yapılandırılmadığı sürece hata verebilir, bu yüzden varsayılan yönteme dönüyoruz.
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  /// Profil fotoğrafını Firebase Storage'a yükler ve URL döndürür.
  Future<String> uploadProfilePictureToStorage(
    File file, {
    void Function(double)? onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu açık değil');

    try {
      // Benzersiz dosya ismi oluştur (Caching sorununu önler)
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child(fileName);

      final uploadTask = ref.putFile(file);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            final progress = event.bytesTransferred / event.totalBytes;
            onProgress(progress);
          }
        });
      }

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Fotoğraf yüklenemedi: $e');
    }
  }

  /// Verilen URL'deki dosyayı Firebase Storage'dan siler.
  Future<void> deleteImageFromStorage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    // Sadece Firebase Storage URL'lerini silmeye çalış (Google profil fotolarını silme)
    if (!imageUrl.contains('firebasestorage.googleapis.com')) return;

    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Dosya silinemedi (Önemsiz olabilir): $e');
    }
  }

  // Sadece profil fotoğrafını güncellemek için
  Future<void> updateProfilePicture(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfilePicture, path);
  }

  // Kullanıcı bilgilerini güncellemek için
  Future<void> updateUserInfo({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String dateOfBirth,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyLastName, lastName);
    await prefs.setString(_keyPhoneNumber, phoneNumber);
    await prefs.setString(_keyDateOfBirth, dateOfBirth);
    await prefs.setString(_keyUserEmail, email);

    // Firestore güncelleme
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth,
      });

      // Firebase Auth profil ismini de güncelle (DisplayName)
      try {
        await user.updateDisplayName('$firstName $lastName');
      } catch (e) {
        debugPrint('DisplayName güncellenemedi: $e');
      }

      // Email güncellemesi hassas işlemdir, burada sadece Firestore'u güncelliyoruz.
      // Gerçek email değişimi için user.verifyBeforeUpdateEmail kullanılmalıdır.
    }
  }

  // Tema tercihini kaydet (0: Sistem, 1: Aydınlık, 2: Karanlık)
  Future<void> updateThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode);
  }

  // Tema tercihini getir (Varsayılan: 0 - Sistem)
  Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyThemeMode) ?? 0;
  }

  // Tema rengini kaydet
  Future<void> updateThemeColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeColor, colorValue);
  }

  Future<int?> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyThemeColor);
  }

  // Dil tercihini kaydet
  Future<void> updateLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
    await FirebaseAuth.instance.setLanguageCode(languageCode);
  }

  // Dil tercihini getir
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'tr'; // Varsayılan: Türkçe
  }

  // Firebase dilini ayarla (Uygulama açılışında kullanılır)
  Future<void> setFirebaseLanguageCode(String languageCode) async {
    await FirebaseAuth.instance.setLanguageCode(languageCode);
  }

  // Kullanıcı çıkış yapmak istediğinde bu metodu çağırın
  Future<void> logout({bool clearFavorites = true}) async {
    await FirebaseAuth.instance.signOut(); // Firebase çıkışı
    final prefs = await SharedPreferences.getInstance();
    // await prefs.clear(); // Tüm verileri temizlemek yerine sadece oturum verilerini siliyoruz
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyFirstName);
    await prefs.remove(_keyLastName);
    await prefs.remove(_keyPhoneNumber);
    await prefs.remove(_keyDateOfBirth);
    await prefs.remove(_keyProfilePicture);
    await prefs.remove(_keyIsSeller);
    await prefs.remove(_keySellerMarketId);

    // Misafir modundan çıkarken favorileri silme, normal çıkışta sil
    if (clearFavorites) {
      await prefs.remove(_keyFavorites);
    }
    // Arama geçmişini silmiyoruz, kullanıcı deneyimi için kalabilir veya isteğe bağlı silinebilir.
  }

  // Kayıtlı kullanıcı verilerini getir
  Future<Map<String, String>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyIsLoggedIn) != true) return null;

    return {
      'id': prefs.getString(_keyUserId) ?? '',
      'email': prefs.getString(_keyUserEmail) ?? '',
      'firstName': prefs.getString(_keyFirstName) ?? '',
      'lastName': prefs.getString(_keyLastName) ?? '',
      'phoneNumber': prefs.getString(_keyPhoneNumber) ?? '',
      'dateOfBirth':
          prefs.getString(_keyDateOfBirth) ?? DateTime.now().toIso8601String(),
      'profilePicture': prefs.getString(_keyProfilePicture) ?? '',
      'sellerMarketId': prefs.getString(_keySellerMarketId) ?? '',
    };
  }

  /// Firestore'dan güncel kullanıcı verilerini çeker ve yerel hafızayı günceller.
  /// Bu metod, çoklu cihaz kullanımında verilerin senkronize kalmasını sağlar.
  Future<Map<String, String>?> refreshUserData(String uid) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;

        String dob = '';
        if (data['dateOfBirth'] is Timestamp) {
          dob = (data['dateOfBirth'] as Timestamp).toDate().toIso8601String();
        } else {
          dob = (data['dateOfBirth'] ?? '').toString();
        }

        final userDataMap = {
          'id': uid,
          'email': (data['email'] ?? '').toString(),
          'firstName': (data['firstName'] ?? '').toString(),
          'lastName': (data['lastName'] ?? '').toString(),
          'phoneNumber': (data['phoneNumber'] ?? '').toString(),
          'dateOfBirth': dob,
          'profilePicture': (data['profilePicture'] ?? '').toString(),
          'sellerMarketId': (data['sellerMarketId'] ?? '').toString(),
        };

        // SharedPreferences güncelle
        final prefs = await SharedPreferences.getInstance();
        // Sadece oturum açıksa güncelle
        if (prefs.getBool(_keyIsLoggedIn) == true) {
          await prefs.setString(_keyFirstName, userDataMap['firstName']!);
          await prefs.setString(_keyLastName, userDataMap['lastName']!);
          await prefs.setString(_keyPhoneNumber, userDataMap['phoneNumber']!);
          await prefs.setString(_keyDateOfBirth, userDataMap['dateOfBirth']!);
          if (userDataMap['profilePicture']!.isNotEmpty) {
            await prefs.setString(
                _keyProfilePicture, userDataMap['profilePicture']!);
          }
          if (userDataMap['sellerMarketId']!.isNotEmpty) {
            await prefs.setString(
                _keySellerMarketId, userDataMap['sellerMarketId']!);
          }
        }
        return userDataMap;
      }
    } catch (e) {
      // Hata durumunda sessizce geç, eski veriyle devam et
    }
    return null;
  }

  /// Firebase Auth oturumu açık ama yerel veri yoksa (örn: uygulama silinip yüklendi,
  /// veri temizlendi veya giriş akışı yarıda kesildi), oturumu kurtarmaya çalışır.
  Future<Map<String, String>?> restoreSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      // Firestore'dan güncel veriyi çek
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic> data = {};
      if (docSnapshot.exists) {
        data = docSnapshot.data()!;
      } else {
        // Kullanıcı Auth'da var ama Firestore'da yoksa, temel bilgilerle devam et
        data = {
          'id': user.uid,
          'email': user.email ?? '',
        };
      }

      // Veri haritasını hazırla
      final userDataMap = {
        'id': user.uid,
        'email': (data['email'] ?? user.email ?? '').toString(),
        'firstName': (data['firstName'] ?? '').toString(),
        'lastName': (data['lastName'] ?? '').toString(),
        'phoneNumber': (data['phoneNumber'] ?? '').toString(),
        'dateOfBirth': (data['dateOfBirth'] is Timestamp)
            ? (data['dateOfBirth'] as Timestamp).toDate().toIso8601String()
            : (data['dateOfBirth'] ?? '').toString(),
        'profilePicture': (data['profilePicture'] ?? '').toString(),
        'sellerMarketId': (data['sellerMarketId'] ?? '').toString(),
      };

      // SharedPreferences'a kaydet (Oturumu yerel olarak aç)
      final prefs = await SharedPreferences.getInstance();
      await _saveUserToPrefs(prefs, userDataMap, rememberMe: true);

      return userDataMap;
    } catch (e) {
      return null;
    }
  }

  // --- KALICI KULLANICI VERİTABANI İŞLEMLERİ ---

  /// Firebase Auth ile kayıt ol ve Firestore'a verileri yaz
  Future<void> registerUserInDb({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String dateOfBirth,
    String? profilePicturePath,
    bool isSeller = false,
  }) async {
    // 1. Firebase Auth Kayıt
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Profil Fotoğrafı Yükleme (Varsa)
    final uid = userCredential.user!.uid;
    String? profilePictureUrl = profilePicturePath;

    // Eğer gelen path yerel bir dosya ise Storage'a yükle
    if (profilePicturePath != null &&
        profilePicturePath.isNotEmpty &&
        File(profilePicturePath).existsSync()) {
      try {
        profilePictureUrl =
            await uploadProfilePictureToStorage(File(profilePicturePath));
      } catch (e) {
        debugPrint('Kayıt sırasında fotoğraf yüklenemedi: $e');
        // Hata olsa bile kayda devam et, resimsiz olsun
      }
    }

    // 3. Firestore Kayıt
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'id': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'profilePicture': profilePictureUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isSeller': isSeller,
      'sellerMarketId': '',
    });

    // 4. Oturumu açık tutmak için yerel verileri kaydet
    final prefs = await SharedPreferences.getInstance();
    final userDataMap = {
      'id': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'profilePicture': profilePictureUrl ?? '',
      'sellerMarketId': '',
    };

    await _saveUserToPrefs(prefs, userDataMap, rememberMe: true);
    await setIsSeller(isSeller);
  }

  Future<List<Map<String, dynamic>>> getAllRegisteredUsers() async {
    // Firebase kullanıldığında tüm kullanıcıları çekmek güvenlik açısından önerilmez.
    return [];
  }

  Future<void> updateUserInDb(
    Map<String, dynamic> updatedFields,
    String email,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // update yerine set ve merge: true kullanarak, doküman yoksa bile oluşturulmasını sağlıyoruz.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updatedFields, SetOptions(merge: true));
    }
  }

  Future<void> changeUserEmailInDb(String oldEmail, String newEmail) async {
    // Firebase Auth'da e-posta değişimi verifyBeforeUpdateEmail ile yapılır.
    // Yerel DB mantığı kaldırıldı.
  }

  Future<void> deleteUserFromDb(String email) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();
    }
  }

  // --- ARAMA GEÇMİŞİ İŞLEMLERİ ---

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentSearches) ?? [];
  }

  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(_keyRecentSearches) ?? [];
    // Varsa çıkar (en başa eklemek için)
    searches.remove(query);
    // Başa ekle
    searches.insert(0, query);
    // Maksimum 10 kayıt tut
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }
    await prefs.setStringList(_keyRecentSearches, searches);
  }

  Future<void> removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(_keyRecentSearches) ?? [];
    searches.remove(query);
    await prefs.setStringList(_keyRecentSearches, searches);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecentSearches);
  }

  // --- FAVORİLER İŞLEMLERİ ---

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavorites) ?? [];
  }

  Future<void> toggleFavorite(String marketId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_keyFavorites) ?? [];
    if (favorites.contains(marketId)) {
      favorites.remove(marketId);
    } else {
      favorites.add(marketId);
    }
    await prefs.setStringList(_keyFavorites, favorites);

    // Firestore Sync: Eğer kullanıcı giriş yapmışsa favorileri buluta kaydet
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'favorites': favorites,
      });
    }
  }

  // --- FAVORİ SATICILAR İŞLEMLERİ ---

  Future<List<String>> getFavoriteSellers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavoriteSellers) ?? [];
  }

  Future<void> toggleFavoriteSeller(String sellerId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_keyFavoriteSellers) ?? [];
    if (favorites.contains(sellerId)) {
      favorites.remove(sellerId);
    } else {
      favorites.add(sellerId);
    }
    await prefs.setStringList(_keyFavoriteSellers, favorites);

    // Firestore Sync
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'favoriteSellers': favorites,
      }, SetOptions(merge: true));
    }
  }

  // --- YORUMLAR İŞLEMLERİ ---

  Future<List<Map<String, dynamic>>> getReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyReviews);
    if (jsonString == null) return [];
    final List<dynamic> list = json.decode(jsonString);
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> addReview(Map<String, dynamic> review) async {
    final prefs = await SharedPreferences.getInstance();
    final reviews = await getReviews();
    reviews.insert(0, review); // En yeni yorumu başa ekle
    await prefs.setString(_keyReviews, json.encode(reviews));
  }

  // Yorum beğenme durumunu değiştir
  Future<void> toggleReviewLike(String reviewId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final reviews = await getReviews();

    final index = reviews.indexWhere((r) => r['id'] == reviewId);
    if (index != -1) {
      final review = reviews[index];
      List<String> likes =
          (review['likes'] as List<dynamic>?)?.cast<String>() ?? [];

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      review['likes'] = likes;
      reviews[index] = review;

      await prefs.setString(_keyReviews, json.encode(reviews));
    }
  }

  // Yorum silme
  Future<void> deleteReview(String reviewId) async {
    final prefs = await SharedPreferences.getInstance();
    final reviews = await getReviews();
    reviews.removeWhere((r) => r['id'] == reviewId);
    await prefs.setString(_keyReviews, json.encode(reviews));
  }

  // Onboarding durumunu kontrol et
  Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  // Onboarding'in görüldüğünü kaydet
  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, true);
  }

  // Satıcı durumu işlemleri
  Future<void> setIsSeller(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsSeller, value);
  }

  // Satıcının seçtiği pazar ID'sini kaydet
  Future<void> updateSellerMarketId(String marketId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySellerMarketId, marketId);
  }

  Future<bool> isSeller() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsSeller) ?? false;
  }

  // --- ÜRÜN YORUMLARI İŞLEMLERİ ---

  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyProductReviews);
    if (jsonString == null) return [];
    final List<dynamic> list = json.decode(jsonString);
    final allReviews = list.cast<Map<String, dynamic>>();
    return allReviews.where((r) => r['productId'] == productId).toList();
  }

  Future<List<Map<String, dynamic>>> getAllProductReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyProductReviews);
    if (jsonString == null) return [];
    final List<dynamic> list = json.decode(jsonString);
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> addProductReview(Map<String, dynamic> review) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyProductReviews);
    List<Map<String, dynamic>> reviews = [];
    if (jsonString != null) {
      reviews = json.decode(jsonString).cast<Map<String, dynamic>>();
    }
    reviews.insert(0, review);
    await prefs.setString(_keyProductReviews, json.encode(reviews));
  }

  // --- PAZAR VE SATICI İŞLEMLERİ (MOCK) ---

  // Belirli bir pazarın satıcılarını getirir
  Future<List<Map<String, dynamic>>> getMarketSellers(String marketId) async {
    // Simüle edilmiş ağ gecikmesi
    await Future.delayed(const Duration(seconds: 1));

    // Gerçek API entegrasyonunda burası şöyle olabilir:
    // final response = await http.get(Uri.parse('$baseUrl/markets/$marketId/sellers'));
    // return List<Map<String, dynamic>>.from(json.decode(response.body));

    return [
      {'id': '1', 'name': 'Ahmet Yılmaz', 'rating': 4.5},
      {'id': '2', 'name': 'Ayşe Demir', 'rating': 4.8},
      {'id': '3', 'name': 'Mehmet Öztürk', 'rating': 4.2},
      {'id': '4', 'name': 'Fatma Kaya', 'rating': 4.6},
    ];
  }

  /// Belirli bir pazara kayıtlı satıcıları Firestore'dan getirir
  Future<List<Map<String, dynamic>>> fetchSellersForMarket(
      String marketId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('sellerMarketId', isEqualTo: marketId)
          .where('isSeller', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Satıcılar çekilirken hata: $e');
      return [];
    }
  }

  // Belirli bir satıcının ürünlerini getirir
  Future<List<Map<String, dynamic>>> getSellerProducts(String sellerId) async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      {'name': 'Domates', 'price': 25.0, 'unit': 'kg', 'inStock': true},
      {'name': 'Salatalık', 'price': 15.0, 'unit': 'kg', 'inStock': true},
      {'name': 'Biber', 'price': 30.0, 'unit': 'kg', 'inStock': false},
      {'name': 'Patlıcan', 'price': 20.0, 'unit': 'kg', 'inStock': true},
    ];
  }

  // --- ÜRÜN YÖNETİMİ (FIRESTORE) ---

  /// Ürün görselini Storage'a yükler
  Future<String> uploadProductImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu açık değil');
    final ref = FirebaseStorage.instance
        .ref()
        .child('products')
        .child(user.uid)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Satıcının ürünlerini veritabanından çeker
  Future<List<Map<String, dynamic>>> fetchSellerProductsFromDb(
      String sellerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Ürünler çekilirken hata: $e');
      return [];
    }
  }

  /// Satıcının ürünlerini sayfalama ile çeker (Pagination)
  Future<QuerySnapshot<Map<String, dynamic>>> fetchSellerProductsPaginated(
    String sellerId, {
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? category,
  }) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.get();
  }

  /// Yeni ürün ekler
  Future<String> addProductToDb(Map<String, dynamic> productData) async {
    final docRef = await FirebaseFirestore.instance
        .collection('products')
        .add(productData);
    return docRef.id;
  }

  /// Ürünü siler
  Future<void> deleteProductFromDb(String productId) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .delete();
  }

  /// Ürünü günceller
  Future<void> updateProductInDb(
      String productId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update(data);
  }

  // --- TELEFON DOĞRULAMA İŞLEMLERİ ---

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  PhoneAuthCredential getPhoneCredential(
      String verificationId, String smsCode) {
    return PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
  }

  // Yardımcı Metot: Kullanıcı verilerini SharedPreferences'a kaydeder
  Future<void> _saveUserToPrefs(
    SharedPreferences prefs,
    Map<String, String> userDataMap, {
    bool rememberMe = true,
  }) async {
    if (rememberMe) {
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, userDataMap['id']!);
      await prefs.setString(_keyUserEmail, userDataMap['email']!);
      await prefs.setString(_keyFirstName, userDataMap['firstName']!);
      await prefs.setString(_keyLastName, userDataMap['lastName']!);
      await prefs.setString(_keyPhoneNumber, userDataMap['phoneNumber']!);
      await prefs.setString(_keyDateOfBirth, userDataMap['dateOfBirth']!);
      await prefs.setString(_keyProfilePicture, userDataMap['profilePicture']!);
      await prefs.setString(_keySellerMarketId, userDataMap['sellerMarketId']!);
    }
  }
}
