import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    UserCredential userCredential;
    try {
      userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        throw Exception('E-posta veya şifreyi hatalı girdiniz.');
      }
      throw Exception('Giriş başarısız: ${e.message}');
    }

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Giriş başarısız: Kullanıcı bilgisi alınamadı.');
    }

    final uid = user.uid;

    // Firestore'dan güncel veriyi çek
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        // Eğer kullanıcı veritabanında varsa, yerel hafızayı güncelle
        final data = userDoc.data()!;
        await prefs.setString(_keyFirstName, data['firstName'] ?? '');
        await prefs.setString(_keyLastName, data['lastName'] ?? '');
        await prefs.setString(_keySellerMarketId, data['sellerMarketId'] ?? '');
        // Diğer alanlar da güncellenebilir...
      }
    } catch (e) {
      debugPrint('Firestore verisi çekilemedi: $e');
    }

    // İsim soyisim gibi verileri yerel hafızadan kurtarmayı dene
    // (Yeni cihazda bu veriler boş gelecektir, bu Firestore'suz yapının kısıtıdır)
    final userDataMap = {
      'id': uid,
      'email': email,
      'firstName': prefs.getString(_keyFirstName) ?? '',
      'lastName': prefs.getString(_keyLastName) ?? '',
      'phoneNumber': prefs.getString(_keyPhoneNumber) ?? '',
      'dateOfBirth': prefs.getString(_keyDateOfBirth) ?? '',
      'profilePicture': prefs.getString(_keyProfilePicture) ?? '',
      'sellerMarketId': prefs.getString(_keySellerMarketId) ?? '',
    };

    if (rememberMe) {
      await _saveUserToPrefs(prefs, userDataMap, rememberMe: true);
    }

    return userDataMap;
  }

  /// E-posta ve şifre ile yeni kullanıcı oluşturur.
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi ViewModel tarafında veya burada detaylandırılabilir
      throw Exception(e.message ?? 'Kayıt oluşturulamadı.');
    }
  }

  /// Şifre sıfırlama e-postası gönderir.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi.';
          break;
        default:
          message = 'İşlem başarısız: ${e.message}';
      }
      throw Exception(message);
    }
  }

  /// Google ile giriş yap
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final prefs = await SharedPreferences.getInstance();

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

        // Firestore kontrolü yerine Auth metadata ile yeni kullanıcı kontrolü
        bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        // İsim soyisim ayrıştırma
        String firstName = '';
        String lastName = '';
        if (user.displayName != null) {
          final parts = user.displayName!.split(' ');
          if (parts.isNotEmpty) {
            firstName = parts.first;
            if (parts.length > 1) {
              lastName = parts.sublist(1).join(' ');
            }
          }
        }

        // 5. Verileri SharedPreferences'a kaydet
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, uid);
        await prefs.setString(_keyUserEmail, user.email ?? '');
        await prefs.setString(_keyFirstName, firstName);
        await prefs.setString(_keyLastName, lastName);

        if (user.photoURL != null) {
          await prefs.setString(_keyProfilePicture, user.photoURL!);
        }

        return userCredential;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
              'Bu e-posta adresiyle daha önce farklı bir yöntemle giriş yapılmış.';
          break;
        case 'invalid-credential':
          message = 'Geçersiz kimlik bilgileri.';
          break;
        case 'operation-not-allowed':
          message = 'Google girişi sunucu tarafında etkinleştirilmemiş.';
          break;
        case 'user-disabled':
          message = 'Kullanıcı hesabı devre dışı bırakılmış.';
          break;
        case 'user-not-found':
          message = 'Kullanıcı bulunamadı.';
          break;
        case 'wrong-password':
          message = 'Hatalı şifre.';
          break;
        case 'invalid-verification-code':
          message = 'Geçersiz doğrulama kodu.';
          break;
        case 'invalid-verification-id':
          message = 'Geçersiz doğrulama kimliği.';
          break;
        default:
          message = 'Giriş başarısız: ${e.message}';
      }
      throw Exception(message);
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed') {
        throw Exception(
            'Google girişi yapılamadı. Lütfen Firebase konsolunda SHA-1 parmak izinin ekli olduğundan emin olun.');
      }
      if (e.code == 'network_error') {
        throw Exception('İnternet bağlantınızı kontrol edin.');
      }
      throw Exception('Google giriş hatası: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('Google ile giriş yapılırken bir hata oluştu: $e');
    }
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

    // Sadece Firebase Auth profil ismini güncelle
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName('$firstName $lastName');
      } catch (e) {
        debugPrint('DisplayName güncellenemedi: $e');
      }
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

    // Google oturumunu da kapat (Tekrar girişte hesap seçimi için)
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Google çıkış hatası: $e');
    }

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
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'id': uid,
          'email': data['email']?.toString() ?? '',
          'firstName': data['firstName']?.toString() ?? '',
          'lastName': data['lastName']?.toString() ?? '',
          'phoneNumber': data['phoneNumber']?.toString() ?? '',
          'dateOfBirth': data['dateOfBirth']?.toString() ?? '',
          'profilePicture': data['profilePicture']?.toString() ?? '',
          'sellerMarketId': data['sellerMarketId']?.toString() ?? '',
          'stallName': data['stallName']?.toString() ?? '',
          'stallDescription': data['stallDescription']?.toString() ?? '',
          'stallHours': data['stallHours']?.toString() ?? '',
          'instagramLink': data['instagramLink']?.toString() ?? '',
          'facebookLink': data['facebookLink']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('Kullanıcı verisi yenilenemedi: $e');
    }
    return null;
  }

  /// Firebase Auth oturumu açık ama yerel veri yoksa (örn: uygulama silinip yüklendi,
  /// veri temizlendi veya giriş akışı yarıda kesildi), oturumu kurtarmaya çalışır.
  Future<Map<String, String>?> restoreSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // İsim soyisim ayrıştırma
    String firstName = '';
    String lastName = '';
    if (user.displayName != null) {
      final parts = user.displayName!.split(' ');
      if (parts.isNotEmpty) {
        firstName = parts.first;
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }
    }

    // Firestore yok, sadece Auth verisi ile basit oturum kurtarma
    final userDataMap = {
      'id': user.uid,
      'email': user.email ?? '',
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': user.phoneNumber ?? '',
      'dateOfBirth': '',
      'profilePicture': user.photoURL ?? '',
      'sellerMarketId': '',
    };

    final prefs = await SharedPreferences.getInstance();
    await _saveUserToPrefs(prefs, userDataMap, rememberMe: true);
    return userDataMap;
  }

  // --- KALICI KULLANICI VERİTABANI İŞLEMLERİ ---

  Future<void> updateUserInDb(
    Map<String, dynamic> updatedFields,
    String email,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updatedFields, SetOptions(merge: true));
    }
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
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    // Kullanıcı giriş yapmışsa Firestore'dan çek
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['favoriteMarkets'] != null) {
            final List<dynamic> favs = data['favoriteMarkets'];
            final List<String> stringFavs =
                favs.map((e) => e.toString()).toList();

            // Yerel veriyi güncelle (Senkronizasyon için)
            await prefs.setStringList(_keyFavorites, stringFavs);
            return stringFavs;
          }
        }
      } catch (e) {
        debugPrint('Favori pazarlar çekilemedi: $e');
      }
    }

    return prefs.getStringList(_keyFavorites) ?? [];
  }

  Future<void> toggleFavorite(String marketId) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    // 1. Yerel Güncelleme (Hız için)
    List<String> favorites = prefs.getStringList(_keyFavorites) ?? [];
    if (favorites.contains(marketId)) {
      favorites.remove(marketId);
    } else {
      favorites.add(marketId);
    }
    await prefs.setStringList(_keyFavorites, favorites);

    // 2. Firestore Güncelleme (Kalıcılık için)
    if (user != null) {
      try {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        if (favorites.contains(marketId)) {
          // Favorilere ekle
          await userRef.update({
            'favoriteMarkets': FieldValue.arrayUnion([marketId])
          });
        } else {
          // Favorilerden çıkar
          await userRef.update({
            'favoriteMarkets': FieldValue.arrayRemove([marketId])
          });
        }
      } catch (e) {
        debugPrint('Favori pazar güncellenemedi: $e');
        // Doküman yoksa oluşturmayı dene (Örn: Eski kullanıcılar için)
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'favoriteMarkets': favorites}, SetOptions(merge: true));
        } catch (e2) {
          debugPrint('Kullanıcı dokümanı oluşturulamadı: $e2');
        }
      }
    }
  }

  // --- FAVORİ SATICILAR İŞLEMLERİ ---

  Future<List<String>> getFavoriteSellers() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['favoriteSellers'] != null) {
            final List<dynamic> favs = data['favoriteSellers'];
            final List<String> stringFavs =
                favs.map((e) => e.toString()).toList();

            // Yerel veriyi güncelle (Senkronizasyon için)
            await prefs.setStringList(_keyFavoriteSellers, stringFavs);
            return stringFavs;
          }
        }
      } catch (e) {
        debugPrint('Favori satıcılar çekilemedi: $e');
      }
    }

    return prefs.getStringList(_keyFavoriteSellers) ?? [];
  }

  /// Satıcıya bildirim gönderir (Firestore'a yazar)
  Future<void> sendSellerNotification(
      String sellerId, String title, String body,
      {Map<String, dynamic>? metadata}) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Bildirim gönderilemedi: $e');
    }
  }

  /// Kullanıcıya bildirim gönderir (Firestore'a yazar)
  /// NOT: Bu metot şu an sadece satıcı bir yoruma yanıt verdiğinde kullanılmaktadır.
  Future<void> sendUserNotification(String userId, String title, String body,
      {Map<String, dynamic>? metadata}) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Bildirim gönderilemedi: $e');
    }
  }

  /// Kullanıcının bildirimlerini dinler (Stream)
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Bildirimi okundu olarak işaretler
  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Tüm bildirimleri okundu olarak işaretler
  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  /// Bildirimi siler
  Future<void> deleteNotification(String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Tüm bildirimleri siler
  Future<void> deleteAllNotifications(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> toggleFavoriteSeller(String sellerId) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    // Önce yerel güncellemeyi yap (Hızlı tepki için)
    List<String> favorites = prefs.getStringList(_keyFavoriteSellers) ?? [];
    final bool isFavorite = favorites.contains(sellerId);

    if (isFavorite) {
      favorites.remove(sellerId);
    } else {
      favorites.add(sellerId);
    }
    await prefs.setStringList(_keyFavoriteSellers, favorites);

    // Firestore güncellemesi
    if (user != null) {
      try {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        if (isFavorite) {
          // Favorilerden çıkar
          await userRef.update({
            'favoriteSellers': FieldValue.arrayRemove([sellerId])
          });
        } else {
          // Favorilere ekle
          await userRef.update({
            'favoriteSellers': FieldValue.arrayUnion([sellerId])
          });

          // Satıcıya bildirim gönder
          await sendSellerNotification(
            sellerId,
            'Yeni Takipçi! 🎉',
            'Bir kullanıcı sizi favori satıcılarına ekledi.',
          );
        }
      } catch (e) {
        debugPrint('Favori satıcı güncellenemedi: $e');
      }
    }
  }

  /// Favori satıcıların detaylarını Firestore'dan çeker
  Future<List<Map<String, dynamic>>> fetchFavoriteSellersDetails() async {
    final favoriteIds = await getFavoriteSellers();
    if (favoriteIds.isEmpty) return [];

    try {
      // Firestore 'in' sorgusu en fazla 10 eleman kabul eder, bu yüzden chunk'lara bölmek gerekebilir.
      // Şimdilik basitlik adına ilk 10 tanesini veya döngü ile çekmeyi tercih edebiliriz.
      // Burada döngü ile tek tek çekmek daha güvenli (az sayıda favori varsayımıyla).
      List<Map<String, dynamic>> sellers = [];
      for (String id in favoriteIds) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          sellers.add(data);
        }
      }
      return sellers;
    } catch (e) {
      debugPrint('Favori satıcı detayları çekilemedi: $e');
      return [];
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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('product_reviews')
          .where('productId', isEqualTo: productId)
          .get();

      final reviews = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Tarihe göre sırala (Yeniden eskiye)
      reviews.sort((a, b) {
        final dateA = a['date'] ?? '';
        final dateB = b['date'] ?? '';
        return dateB.compareTo(dateA);
      });

      return reviews;
    } catch (e) {
      debugPrint('Ürün yorumları çekilirken hata: $e');
      return [];
    }
  }

  /// Belirtilen ürün ID'lerine ait yorumları getirir (Chunking ile)
  Future<List<Map<String, dynamic>>> getReviewsForProducts(
      List<String> productIds) async {
    if (productIds.isEmpty) return [];
    List<Map<String, dynamic>> allReviews = [];

    // Firestore 'whereIn' limiti 10 olduğu için listeyi parçalara bölüyoruz
    for (var i = 0; i < productIds.length; i += 10) {
      final end = (i + 10 < productIds.length) ? i + 10 : productIds.length;
      final chunk = productIds.sublist(i, end);

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('product_reviews')
            .where('productId', whereIn: chunk)
            .get();

        final reviews = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        allReviews.addAll(reviews);
      } catch (e) {
        debugPrint('Yorumlar çekilirken hata: $e');
      }
    }

    // Tarihe göre sırala (Yeniden eskiye)
    allReviews.sort((a, b) {
      final dateA = a['date'] ?? '';
      final dateB = b['date'] ?? '';
      return dateB.compareTo(dateA);
    });

    return allReviews;
  }

  /// Kullanıcının yaptığı tüm ürün değerlendirmelerini getirir
  Future<List<Map<String, dynamic>>> getUserProductReviews(
      String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('product_reviews')
          .where('userId', isEqualTo: userId)
          .get();

      // Her yorum için ürün detaylarını da çekmek üzere Future.wait kullanıyoruz
      final reviews = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        data['id'] = doc.id;

        // Ürün bilgilerini çek
        if (data['productId'] != null) {
          try {
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(data['productId'])
                .get();

            if (productDoc.exists) {
              final pData = productDoc.data();

              // Ürün detay sayfasına yönlendirme için tüm veriyi sakla
              if (pData != null) {
                data['product'] = pData;
                data['product']['id'] = productDoc.id;
              }

              data['productName'] = pData?['name'];
              data['productImage'] = pData?['imagePath'];

              // Satıcı ismini çek
              if (pData?['sellerId'] != null) {
                final sellerDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(pData!['sellerId'])
                    .get();
                if (sellerDoc.exists) {
                  final sData = sellerDoc.data();
                  data['sellerName'] = sData?['stallName'] ??
                      '${sData?['firstName'] ?? ''} ${sData?['lastName'] ?? ''}'
                          .trim();
                }
              }
            } else {
              data['productName'] = 'Silinmiş Ürün';
            }
          } catch (e) {
            debugPrint('Yorum detayları yüklenirken hata: $e');
          }
        }

        return data;
      }));

      // Tarihe göre sırala (Yeniden eskiye)
      reviews.sort((a, b) {
        final dateA = a['date'] ?? '';
        final dateB = b['date'] ?? '';
        return dateB.compareTo(dateA);
      });

      return reviews;
    } catch (e) {
      debugPrint('Kullanıcı değerlendirmeleri çekilirken hata: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllProductReviews() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('product_reviews').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Tüm ürün yorumları çekilirken hata: $e');
      return [];
    }
  }

  Future<void> addProductReview(Map<String, dynamic> review) async {
    try {
      // Satıcı ID'sini bul ve yoruma ekle (Gelecekteki sorgular için)
      String? sellerId;
      if (review['productId'] != null) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(review['productId'])
            .get();
        sellerId = productDoc.data()?['sellerId'];
        if (sellerId != null) {
          review['sellerId'] = sellerId;
        }
      }

      String reviewId;
      // ID varsa onu kullan, yoksa Firestore oluştursun
      if (review.containsKey('id') && review['id'] != null) {
        reviewId = review['id'];
        await FirebaseFirestore.instance
            .collection('product_reviews')
            .doc(reviewId)
            .set(review);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('product_reviews')
            .add(review);
        reviewId = docRef.id;
      }

      // Bildirim gönder
      if (sellerId != null) {
        await sendSellerNotification(sellerId, 'Yeni Ürün Yorumu 💬',
            'Bir ürününüze yeni yorum yapıldı: "${review['comment']}"',
            metadata: {
              'type': 'new_review',
              'productId': review['productId'],
              'reviewId': reviewId,
            });
      }
    } catch (e) {
      debugPrint('Ürün yorumu eklenirken hata: $e');
      throw e;
    }
  }

  /// Ürün yorumunu günceller
  Future<void> updateProductReview(
      String reviewId, String newComment, double newRating) async {
    try {
      await FirebaseFirestore.instance
          .collection('product_reviews')
          .doc(reviewId)
          .update({
        'comment': newComment,
        'rating': newRating,
        'isEdited': true,
      });
    } catch (e) {
      debugPrint('Ürün yorumu güncellenirken hata: $e');
      throw e;
    }
  }

  /// Ürün yorumunu siler (Firestore)
  Future<void> deleteProductReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('product_reviews')
          .doc(reviewId)
          .delete();
    } catch (e) {
      debugPrint('Ürün yorumu silinirken hata: $e');
      throw e;
    }
  }

  /// Ürün yorumu beğenme durumunu değiştir (Firestore)
  Future<void> toggleProductReviewLike(String reviewId, String userId) async {
    final docRef =
        FirebaseFirestore.instance.collection('product_reviews').doc(reviewId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      List<String> likes = List<String>.from(data['likes'] ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      transaction.update(docRef, {'likes': likes});
    });
  }

  // Yorum yanıtlama
  Future<void> replyToProductReview(String reviewId, String reply) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('product_reviews')
          .doc(reviewId);

      await docRef.update({
        'sellerReply': reply,
        'replyDate': FieldValue.serverTimestamp(),
      });

      // Müşteriye bildirim gönder
      final doc = await docRef.get();
      final data = doc.data();
      if (data != null && data['userId'] != null) {
        await sendUserNotification(
          data['userId'],
          'Satıcı Yanıt Verdi 💬',
          'Satıcı yorumunuza yanıt verdi: "$reply"',
          metadata: {
            'type': 'review_reply',
            'productId': data['productId'],
            'reviewId': reviewId,
          },
        );
      }
    } catch (e) {
      debugPrint('Yorum yanıtlanırken hata: $e');
      throw e;
    }
  }

  // --- ÜRÜN SORULARI İŞLEMLERİ ---

  Future<List<Map<String, dynamic>>> getProductQuestions(
      String productId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('product_questions')
          .where('productId', isEqualTo: productId)
          .get();

      final questions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Tarihe göre sırala (Yeniden eskiye)
      questions.sort((a, b) {
        final dateA = a['date'] ?? '';
        final dateB = b['date'] ?? '';
        return dateB.compareTo(dateA);
      });

      return questions;
    } catch (e) {
      debugPrint('Ürün soruları çekilirken hata: $e');
      return [];
    }
  }

  /// Satıcıya sorulan soruları getirir
  Future<List<Map<String, dynamic>>> getSellerQuestions(String sellerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('product_questions')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      final questions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Tarihe göre sırala (Yeniden eskiye)
      questions.sort((a, b) {
        final dateA = a['date'] ?? '';
        final dateB = b['date'] ?? '';
        return dateB.compareTo(dateA);
      });

      return questions;
    } catch (e) {
      debugPrint('Satıcı soruları çekilirken hata: $e');
      return [];
    }
  }

  /// Satıcıya sorulan yanıtlanmamış soruların sayısını dinler
  Stream<int> getUnansweredQuestionsCount(String sellerId) {
    return FirebaseFirestore.instance
        .collection('product_questions')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final reply = data['sellerReply'];
        return reply == null || reply.toString().trim().isEmpty;
      }).length;
    });
  }

  /// Kullanıcının sorduğu tüm ürün sorularını getirir
  Future<List<Map<String, dynamic>>> getUserProductQuestions(
      String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('product_questions')
          .where('userId', isEqualTo: userId)
          .get();

      // Her soru için ürün detaylarını da çekmek üzere Future.wait kullanıyoruz
      final questions = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        data['id'] = doc.id;

        // Ürün bilgilerini çek
        if (data['productId'] != null) {
          try {
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(data['productId'])
                .get();

            if (productDoc.exists) {
              final pData = productDoc.data();

              // Ürün detay sayfasına yönlendirme için tüm veriyi sakla
              if (pData != null) {
                data['product'] = pData;
                data['product']['id'] = productDoc.id;
              }

              data['productName'] = pData?['name'];
              data['productImage'] = pData?['imagePath'];

              // Satıcı ismini çek
              if (pData?['sellerId'] != null) {
                final sellerDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(pData!['sellerId'])
                    .get();
                if (sellerDoc.exists) {
                  final sData = sellerDoc.data();
                  data['sellerName'] = sData?['stallName'] ??
                      '${sData?['firstName'] ?? ''} ${sData?['lastName'] ?? ''}'
                          .trim();
                }
              }
            } else {
              data['productName'] = 'Silinmiş Ürün';
            }
          } catch (e) {
            debugPrint('Soru detayları yüklenirken hata: $e');
          }
        }

        return data;
      }));

      // Tarihe göre sırala (Yeniden eskiye)
      questions.sort((a, b) {
        final dateA = a['date'] ?? '';
        final dateB = b['date'] ?? '';
        return dateB.compareTo(dateA);
      });

      return questions;
    } catch (e) {
      debugPrint('Kullanıcı soruları çekilirken hata: $e');
      return [];
    }
  }

  /// Belirtilen ürün ID'lerine ait soruları getirir (Chunking ile)
  Future<List<Map<String, dynamic>>> getQuestionsForProducts(
      List<String> productIds) async {
    if (productIds.isEmpty) return [];
    List<Map<String, dynamic>> allQuestions = [];

    for (var i = 0; i < productIds.length; i += 10) {
      final end = (i + 10 < productIds.length) ? i + 10 : productIds.length;
      final chunk = productIds.sublist(i, end);

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('product_questions')
            .where('productId', whereIn: chunk)
            .get();

        final questions = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        allQuestions.addAll(questions);
      } catch (e) {
        debugPrint('Sorular çekilirken hata: $e');
      }
    }

    allQuestions.sort((a, b) {
      final dateA = a['date'] ?? '';
      final dateB = b['date'] ?? '';
      return dateB.compareTo(dateA);
    });

    return allQuestions;
  }

  Future<void> replyToProductQuestion(String questionId, String reply) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('product_questions')
          .doc(questionId);

      await docRef.update({
        'sellerReply': reply,
        'replyDate': FieldValue.serverTimestamp(),
      });

      // Müşteriye bildirim gönder
      final doc = await docRef.get();
      final data = doc.data();
      if (data != null && data['userId'] != null) {
        await sendUserNotification(
          data['userId'],
          'Satıcı Sorunuzu Yanıtladı 💬',
          'Satıcı sorunuza yanıt verdi: "$reply"',
          metadata: {
            'type': 'question_reply',
            'productId': data['productId'],
            'questionId': questionId,
          },
        );
      }
    } catch (e) {
      debugPrint('Soru yanıtlanırken hata: $e');
      throw e;
    }
  }

  Future<void> askProductQuestion(Map<String, dynamic> question) async {
    try {
      String? sellerId;
      if (question['productId'] != null) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(question['productId'])
            .get();
        sellerId = productDoc.data()?['sellerId'];
        if (sellerId != null) {
          question['sellerId'] = sellerId;
        }
      }

      final docRef = await FirebaseFirestore.instance
          .collection('product_questions')
          .add(question);

      if (sellerId != null) {
        await sendSellerNotification(sellerId, 'Yeni Ürün Sorusu ❓',
            'Bir ürününüze yeni soru soruldu: "${question['question']}"',
            metadata: {
              'type': 'new_question',
              'productId': question['productId'],
              'questionId': docRef.id,
            });
      }
    } catch (e) {
      debugPrint('Soru sorulurken hata: $e');
      throw e;
    }
  }

  /// Ürün sorusunu günceller
  Future<void> updateProductQuestion(
      String questionId, String newQuestion) async {
    try {
      await FirebaseFirestore.instance
          .collection('product_questions')
          .doc(questionId)
          .update({
        'question': newQuestion,
        'isEdited': true,
      });
    } catch (e) {
      debugPrint('Ürün sorusu güncellenirken hata: $e');
      throw e;
    }
  }

  /// Ürün sorusunu siler (Firestore)
  Future<void> deleteProductQuestion(String questionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('product_questions')
          .doc(questionId)
          .delete();
    } catch (e) {
      debugPrint('Ürün sorusu silinirken hata: $e');
      throw e;
    }
  }

  // --- PAZAR VE SATICI İŞLEMLERİ (MOCK) ---

  // Belirli bir pazarın satıcılarını getirir
  Future<List<Map<String, dynamic>>> getMarketSellers(String marketId) async {
    return await fetchSellersForMarket(marketId);
  }

  /// Belirli bir pazara kayıtlı satıcıları Firestore'dan getirir
  Future<List<Map<String, dynamic>>> fetchSellersForMarket(
      String marketId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isSeller', isEqualTo: true)
          .where('sellerMarketId', isEqualTo: marketId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Satıcılar çekilirken hata: $e');
      return [];
    }
  }

  // Belirli bir satıcının ürünlerini getirir
  Future<List<Map<String, dynamic>>> getSellerProducts(String sellerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Ürünler çekilirken hata: $e');
      return [];
    }
  }

  // --- SATICI İSTATİSTİKLERİ ---

  /// Satıcının ortalama puanını ve yorum sayısını Firestore'dan hesaplar
  Future<Map<String, dynamic>> getSellerStats(String sellerId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('seller_reviews')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'averageRating': 0.0, 'reviewCount': 0};
      }

      double totalRating = 0.0;
      for (var doc in querySnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      double average = totalRating / querySnapshot.docs.length;
      return {
        'averageRating': average,
        'reviewCount': querySnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Satıcı istatistikleri alınamadı: $e');
      return {'averageRating': 0.0, 'reviewCount': 0};
    }
  }

  /// Aynı isme sahip ürünü satan diğer satıcıları bulur
  Future<List<Map<String, dynamic>>> getSellersSellingProduct(
      String productName, String excludeSellerId) async {
    try {
      // 1. Aynı isme sahip diğer ürünleri bul
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: productName)
          .get();

      final otherProducts = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['sellerId'] != excludeSellerId)
          .toList();

      if (otherProducts.isEmpty) return [];

      // 2. Bu ürünlerin satıcı ID'lerini topla
      final sellerIds =
          otherProducts.map((p) => p['sellerId'] as String).toSet();

      // 3. Satıcı detaylarını çek
      List<Map<String, dynamic>> sellers = [];
      for (var id in sellerIds) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userData['id'] = userDoc.id;

          // İlgili ürünün detaylarını (fiyat, birim, konum) al
          final productEntry =
              otherProducts.firstWhere((p) => p['sellerId'] == id);
          userData['productPrice'] = productEntry['price'];
          userData['productUnit'] = productEntry['unit'];
          userData['stallLocation'] = productEntry['stallLocation'];

          sellers.add(userData);
        }
      }
      return sellers;
    } catch (e) {
      debugPrint('Diğer satıcılar bulunurken hata: $e');
      return [];
    }
  }

  // --- ÜRÜN YÖNETİMİ (FIRESTORE) ---

  /// Ürün görselini Storage'a yükler
  Future<String> uploadProductImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu açık değil');

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('products')
        .child(user.uid)
        .child(fileName);

    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final UploadTask task = ref.putFile(file, metadata);
    final TaskSnapshot snapshot = await task;

    if (snapshot.state == TaskState.success) {
      return await ref.getDownloadURL();
    } else {
      throw Exception('Resim yüklenemedi. Durum: ${snapshot.state}');
    }
  }

  /// Yorum görselini Storage'a yükler
  Future<String> uploadReviewImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu açık değil');
    final ref = FirebaseStorage.instance
        .ref()
        .child('product_reviews')
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

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Ürünler çekilirken hata: $e');
      return [];
    }
  }

  /// Satıcının ürünlerini sayfalama ile çeker (Pagination)
  // Firestore dönüş tipi (QuerySnapshot) içerdiği için bu metodu devre dışı bırakıyoruz
  /*
  Future<void> fetchSellerProductsPaginated(
    String sellerId, {
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? category,
  }) async {
    // ...
  }
  */

  /// Yeni ürün ekler
  Future<String> addProductToDb(Map<String, dynamic> productData) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('products')
          .add(productData);
      return docRef.id;
    } catch (e) {
      debugPrint('Ürün eklenirken hata: $e');
      throw e;
    }
  }

  /// Ürünü siler
  Future<void> deleteProductFromDb(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      debugPrint('Ürün silinirken hata: $e');
      throw e;
    }
  }

  /// Ürünü günceller
  Future<void> updateProductInDb(
      String productId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update(data);
    } catch (e) {
      debugPrint('Ürün güncellenirken hata: $e');
      throw e;
    }
  }

  /// Ürün görüntülenme sayısını artırır
  Future<void> incrementProductViewCount(String productId) async {
    try {
      final productRef =
          FirebaseFirestore.instance.collection('products').doc(productId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) return;

        final currentViews =
            (snapshot.data()?['viewCount'] as num?)?.toInt() ?? 0;
        final newViews = currentViews + 1;

        transaction.update(productRef, {'viewCount': newViews});

        // 50 görüntülenmeye ulaştığında bildirim gönder
        if (newViews == 50) {
          final sellerId = snapshot.data()?['sellerId'] as String?;
          final productName = snapshot.data()?['name'] as String? ?? 'Ürününüz';

          if (sellerId != null) {
            final notificationRef = FirebaseFirestore.instance
                .collection('users')
                .doc(sellerId)
                .collection('notifications')
                .doc();

            transaction.set(notificationRef, {
              'title': 'Tebrikler! 🎉',
              'body': '"$productName" 50 görüntülenmeye ulaştı.',
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Görüntülenme sayısı artırılamadı: $e');
    }
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

  /// Kullanıcının profil fotoğrafı değiştiğinde, geçmiş yorumlardaki ve sorulardaki fotoğrafı da günceller.
  Future<void> updateUserProfileInContent(
      String userId, String newPhotoUrl) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    // 1. Yorumları Güncelle
    final reviewsQuery = await FirebaseFirestore.instance
        .collection('product_reviews')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in reviewsQuery.docs) {
      batch.update(doc.reference, {'userProfilePicture': newPhotoUrl});
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }

    // 2. Soruları Güncelle
    final questionsQuery = await FirebaseFirestore.instance
        .collection('product_questions')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in questionsQuery.docs) {
      batch.update(doc.reference, {'userProfilePicture': newPhotoUrl});
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  /// Kullanıcının adı değiştiğinde, geçmiş yorumlardaki ve sorulardaki ismi de günceller.
  Future<void> updateUserNameInContent(String userId, String newName) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    // 1. Yorumları Güncelle
    final reviewsQuery = await FirebaseFirestore.instance
        .collection('product_reviews')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in reviewsQuery.docs) {
      batch.update(doc.reference, {'userName': newName});
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }

    // 2. Soruları Güncelle
    final questionsQuery = await FirebaseFirestore.instance
        .collection('product_questions')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in questionsQuery.docs) {
      batch.update(doc.reference, {'userName': newName});
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  /// Kullanıcıyı şifre ile yeniden doğrular (Hesap silme vb. işlemler için)
  Future<void> reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu açık değil.');

    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Girdiğiniz şifre hatalı.');
      }
      throw Exception('Doğrulama başarısız: ${e.message}');
    }
  }
}
