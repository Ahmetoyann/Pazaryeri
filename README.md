# Pazaryeri

Semt pazarları, ürün arama, doluluk oranları, satıcı yönetimi ve bildirim/şikayet yönetimi sağlayan kapsamlı bir Flutter uygulaması.

## Özellikler

### 👤 Müşteri Paneli
- **Kullanıcı Yönetimi:**
  - Giriş Yap / Kayıt Ol (E-posta & Şifre, Google ile Giriş).
  - **Misafir Modu:** Üye olmadan uygulamayı inceleme imkanı.
  - Profil Düzenleme: Fotoğraf yükleme, kişisel bilgileri güncelleme.
  - Şifre Sıfırlama.
- **Pazaryeri Keşfi:**
  - Konuma dayalı en yakın pazar listeleme.
  - İl/İlçe bazlı pazar filtreleme.
  - Pazar detayları, açık olduğu günler ve konum bilgisi.
- **Alışveriş & Etkileşim:**
  - **Ürün Arama:** Ürün ismine göre pazar ve satıcı arama.
  - **Satıcılar:** Pazardaki satıcıları ve ürünlerini görüntüleme.
  - **Favoriler:** Pazar ve satıcıları favorilere ekleme.
  - **Değerlendirme:** Pazarlara ve ürünlere yorum yapma, puan verme.
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
  - Ürünlere yapılan yorumları görüntüleme ve yanıtlama.
- **Profil Yönetimi:**
  - Tezgah adı, açıklama ve çalışma saatleri düzenleme.
  - Sosyal medya hesaplarını ekleme.
  - Pazar yeri seçimi ve değiştirme.

### ⚙️ Genel Özellikler
- **Bildirimler:** Anlık bildirim sistemi (Firebase).
- **Tema:** Karanlık (Dark) ve Aydınlık (Light) mod desteği.
- **Dil:** Türkçe ve İngilizce dil desteği.
- **Harita:** Google Haritalar entegrasyonu ile yol tarifi.

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
- **Modeller:**
  - `Market` modeli `products` alanlarını içerir.
