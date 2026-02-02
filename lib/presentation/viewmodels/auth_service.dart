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
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

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
        }
      } catch (e) {
        debugPrint('Favori satıcı güncellenemedi: $e');
      }
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
    // Firestore kaldırıldı
    return [];
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
    // Firestore kaldırıldı
    return "mock_id";
  }

  /// Ürünü siler
  Future<void> deleteProductFromDb(String productId) async {
    // Firestore kaldırıldı
  }

  /// Ürünü günceller
  Future<void> updateProductInDb(
      String productId, Map<String, dynamic> data) async {
    // Firestore kaldırıldı
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
