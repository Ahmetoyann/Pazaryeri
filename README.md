# Pazaryeri

Semt pazarları, ürün arama, doluluk oranları, satıcı yönetimi ve bildirim/şikayet yönetimi sağlayan kapsamlı bir Flutter uygulaması.

## Özellikler

### 👤 Müşteri Paneli
- **Kullanıcı Yönetimi:**
  - Giriş Yap / Kayıt Ol (Google ile Giriş).
  - **Misafir Modu:** Üye olmadan uygulamayı inceleme imkanı.
  - Profil Düzenleme: Fotoğraf yükleme, kişisel bilgileri güncelleme.

- **Pazaryeri Keşfi:**
  - Konuma dayalı en yakın pazar listeleme.
  - İl/İlçe bazlı pazar filtreleme.
  - Pazar detayları, açık olduğu günler ve konum bilgisi.
- **Alışveriş & Etkileşim:**
  - **Ürün Arama:** Pazar ve satıcı arama.
  - **Satıcılar:** Pazardaki satıcıları ve ürünlerini görüntüleme.
  - **Favoriler:** Pazar ve satıcıları favorilere ekleme.
  - **Değerlendirme:** Pazarlara ve ürünlere yorum yapma, puan verme.
  - **Soru-Cevap:** Satıcılara ürün hakkında soru sorma ve yanıtları takip etme.
- **Bildirim/Şikayet:** Pazaryerleri için şikayet veya bildirim oluşturma.
- **Doluluk Oranları:** Pazaryerlerinin anlık doluluk yüzdelerini görüntüleme.

### 🏪 Satıcı Paneli
- **Ürün Yönetimi:**
  - Fotoğraflı ürün ekleme, düzenleme ve silme.
  - Stok takibi ve fiyat güncelleme.
  - Kategori bazlı ürün yönetimi.
- **İstatistikler:**
  - Toplam görüntülenme, satış ve gelir takibi.
  - Grafiksel verilerle analiz.
- **Müşteri İlişkileri:**
  - Ürünlere yapılan değerlendirmeleri görüntüleme.
  - Ürünlerle ilgili gelen soruları görüntüleme ve yanıtlama.
- **Profil Yönetimi:**
  - Tezgah adı, tarifi ve çalışma saatleri düzenleme.
  - Sosyal medya hesaplarını ekleme.
  - Pazar yeri seçimi ve değiştirme.
  - Şifre Sıfırlama.

### ⚙️ Genel Özellikler
- **Bildirimler:** Anlık bildirim sistemi (Firebase).
- **Tema:** Karanlık (Dark) ve Aydınlık (Light) mod desteği.
- **Dil:** Türkçe ve İngilizce dil desteği.
- **Harita:** Google Haritalar entegrasyonu ile yol tarifi.
- **Bağlantı Kontrolü:** İnternet bağlantısı koptuğunda kullanıcıyı bilgilendirme.

## Proje Mimarisi

Proje **MVVM (Model-View-ViewModel)** mimarisi ve `provider` paketi kullanılarak geliştirilmiştir.

- `lib/core`: Servis arayüzleri ve yardımcı sınıflar (Location, Constants vb.).
- `lib/data`: Veri modelleri ve repository implementasyonları.
- `lib/presentation`:
  - `screens`: Müşteri ve Satıcı ekranları.
  - `viewmodels`: İş mantığını yöneten sınıflar.
  - `widgets`: Tekrar kullanılabilir arayüz bileşenleri.

**Kullanılan Ana Paketler:**
- `provider`: Durum yönetimi.
- `firebase_auth`, `cloud_firestore`, `firebase_storage`: Backend servisleri.
- `geolocator`: Konum işlemleri.
- `image_picker`: Fotoğraf seçimi.
- `shared_preferences`: Yerel veri saklama.
- `fl_chart`: İstatistik grafikleri.
- `google_sign_in`: Google ile giriş.

## Kurulum ve Çalıştırma

1.  Bağımlılıkları yükleyin:
    ```bash
    flutter pub get
    ```
2.  Uygulamayı çalıştırın:
    ```bash
    flutter run
    ```

**Not:** Firebase servislerinin çalışması için `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarının ilgili dizinlere eklenmesi gerekmektedir.

## Gerekli İzinler

Uygulamanın tam fonksiyonlu çalışması için aşağıdaki izinlerin yapılandırılması gerekir:

**Android (`android/app/src/main/AndroidManifest.xml`):**

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**iOS (`ios/Runner/Info.plist`):**

- `NSLocationWhenInUseUsageDescription`: "Uygulama yakınındaki semt pazarlarını bulmak için konumunuza erişim gereklidir."

## Dosya Yapısı ve Eklenenler

- **Ekranlar:**
  - `search_screen.dart`: Ürün arama ekranı.
  - `report_list_screen.dart` & `report_form_screen.dart`: Bildirim listeleme ve oluşturma.
  - `account_screen.dart`: Profil ve ayarlar yönetimi.
  - `seller_questions_screen.dart`: Satıcı soru yönetim ekranı.
  - `my_questions_screen.dart`: Müşteri soru takip ekranı.
  - `notifications_screen.dart`: Bildirim merkezi.
- **Modeller:**
  - `Market` modeli `products` alanlarını içerir.


## 📂 Proje Mimarisi ve Klasör Yapısı

```Pazaryeri
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_icons.dart
│   │   ├── location/
│   │   │   ├── geolocator_location_service.dart
│   │   │   ├── location_service.dart
│   │   │   └── mock_location_service.dart
│   │   └── regions/
│   │       └── provinces.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── address.dart
│   │   │   └── market.dart
│   │   └── repositories/
│   │       └── market_repository.dart
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── Customer/
│   │   │   │   ├── customer_seller_detail_screen.dart
│   │   │   │   ├── edit_profile_screen.dart
│   │   │   │   ├── favorites_screen.dart
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── market_detail_screen.dart
│   │   │   │   ├── market_sellers_screen.dart
│   │   │   │   ├── my_questions_screen.dart
│   │   │   │   ├── my_reports_screen.dart
│   │   │   │   ├── my_reviews_screen.dart
│   │   │   │   ├── notifications_screen.dart
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   ├── products_screen.dart
│   │   │   │   ├── report_form_screen.dart
│   │   │   │   ├── report_list_screen.dart
│   │   │   │   └── search_screen.dart
│   │   │   ├── Seller/
│   │   │   │   ├── favorite_sellers_screen.dart
│   │   │   │   ├── market_sellers_screen.dart
│   │   │   │   ├── seller_add_product_screen.dart
│   │   │   │   ├── seller_edit_profile_screen.dart
│   │   │   │   ├── seller_login_screen.dart
│   │   │   │   ├── seller_main_screen.dart
│   │   │   │   ├── seller_market_selection_screen.dart
│   │   │   │   ├── seller_notifications_screen.dart
│   │   │   │   ├── seller_product_management_screen.dart
│   │   │   │   ├── seller_products_screen.dart
│   │   │   │   ├── seller_products_view_screen.dart
│   │   │   │   ├── seller_questions_screen.dart
│   │   │   │   ├── seller_register_screen.dart
│   │   │   │   ├── seller_reviews_screen.dart
│   │   │   │   ├── seller_settings_screen.dart
│   │   │   │   └── seller_stats_screen.dart
│   │   │   ├── theme_settings_screen.dart
│   │   │   ├── phone_verification_screen.dart
│   │   │   ├── splash_screen.dart
│   │   │   └── user_type_selection_screen.dart
│   │   ├── viewmodels/
│   │   │   ├── app_strings.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── auth_viewmodel.dart
│   │   │   ├── language_viewmodel.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── seller_viewmodel.dart
│   │   │   ├── theme_viewmodel.dart
│   │   │   └── user_model.dart
│   │   └── widgets/
│   │       ├── connectivity_wrapper.dart
│   │       ├── custom_app_bar.dart
│   │       ├── custom_bottom_sheets.dart
│   │       ├── custom_button.dart
│   │       ├── custom_search_bar.dart
│   │       ├── custom_snackbars.dart
│   │       ├── custom_text_field.dart
│   │       ├── empty_state_view.dart
│   │       ├── guest_login_dialog.dart
│   │       ├── loading_overlay.dart
│   │       ├── market_card.dart
│   │       ├── product_card.dart
│   │       ├── side_menu_drawer.dart
│   │       ├── success_dialog.dart
│   │       └── svg_icon.dart
│   ├── app_theme.dart
│   ├── firebase_options.dart
│   └── main.dart

