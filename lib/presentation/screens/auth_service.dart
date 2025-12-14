import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const String _keyIsDarkMode = 'isDarkMode';
  static const String _keyThemeColor = 'themeColor';
  static const String _keyLanguage = 'language';
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keyFavorites = 'favorite_markets';
  static const String _keyReviews = 'market_reviews';
  static const String _keyOnboardingSeen = 'onboarding_seen';

  // --- FIREBASE AUTHENTICATION ---

  /// Firebase ile giriş yap ve kullanıcı verilerini Firestore'dan çekip yerel hafızaya al.
  Future<void> loginWithFirebase(String email, String password) async {
    // 1. Firebase Auth ile giriş
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Firestore'dan kullanıcı detaylarını çek
    final uid = userCredential.user!.uid;
    final docSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;

      // 3. Verileri SharedPreferences'a kaydet (Uygulamanın geri kalanı buradan okuyor)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, uid);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyFirstName, data['firstName'] ?? '');
      await prefs.setString(_keyLastName, data['lastName'] ?? '');
      await prefs.setString(_keyPhoneNumber, data['phoneNumber'] ?? '');
      await prefs.setString(_keyDateOfBirth, data['dateOfBirth'] ?? '');
      if (data['profilePicture'] != null) {
        await prefs.setString(_keyProfilePicture, data['profilePicture']);
      }
    } else {
      throw Exception("Kullanıcı verisi bulunamadı.");
    }
  }

  /// Google ile giriş yap
  Future<void> signInWithGoogle() async {
    // 1. Google Sign-In akışını başlat
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      // Kullanıcı iptal etti
      return;
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

      if (docSnapshot.exists) {
        data = docSnapshot.data()!;
      } else {
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
        };
        await docRef.set(data);
      }

      // 5. Verileri SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, uid);
      await prefs.setString(_keyUserEmail, user.email ?? '');
      await prefs.setString(_keyFirstName, data['firstName'] ?? '');
      await prefs.setString(_keyLastName, data['lastName'] ?? '');
      await prefs.setString(_keyPhoneNumber, data['phoneNumber'] ?? '');
      await prefs.setString(_keyDateOfBirth, data['dateOfBirth'] ?? '');
      if (data['profilePicture'] != null) {
        await prefs.setString(_keyProfilePicture, data['profilePicture']);
      }
    }
  }

  /// Firebase şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
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
      // Email güncellemesi hassas işlemdir, burada sadece Firestore'u güncelliyoruz.
      // Gerçek email değişimi için user.verifyBeforeUpdateEmail kullanılmalıdır.
    }
  }

  // Tema tercihini kaydet
  Future<void> updateThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkMode, isDark);
  }

  // Tema tercihini getir
  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsDarkMode) ?? true; // Varsayılan: Karanlık (true)
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
  }

  // Dil tercihini getir
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'tr'; // Varsayılan: Türkçe
  }

  // Kullanıcı çıkış yapmak istediğinde bu metodu çağırın
  Future<void> logout() async {
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
    };
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
  }) async {
    // 1. Firebase Auth Kayıt
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Firestore Kayıt
    final uid = userCredential.user!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'id': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'profilePicture': profilePicturePath,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedFields);
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
}
