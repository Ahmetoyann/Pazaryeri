# Pazaryeri

Semt pazarları, ürün arama, doluluk oranları ve bildirim/şikayet yönetimi sağlayan Flutter uygulaması.

## Özellikler

- **Kullanıcı Yönetimi:**
  - Giriş Yap / Kayıt Ol (E-posta & Şifre, Google ile Giriş).
  - **Misafir Modu:** Üye olmadan uygulamayı inceleme imkanı.
  - Profil Düzenleme: Fotoğraf yükleme/kırpma, kişisel bilgileri güncelleme.
  - Şifre Sıfırlama.
- **Pazaryeri Keşfi:**
  - Konuma dayalı pazar listeleme.
  - **Tab Gezintisi:** 4 ana sekme (Pazaryeri, Ara, Doluluk, Bildir).
- **Arama:** Ürün ismine göre pazar arama ve adres görüntüleme.
- **Doluluk Oranları:** Pazaryerlerinin anlık doluluk yüzdelerini görüntüleme.
- **Bildirim/Şikayet:** Pazaryerleri için şikayet veya bildirim oluşturma.
- **Diğer:**
  - Favoriler ve Yorumlarım.
  - Tema (Karanlık/Aydınlık) ve Dil (Türkçe/İngilizce) desteği.

## Proje Mimarisi

Proje MVVM (Model-View-ViewModel) mimarisi ve `provider` paketi kullanılarak geliştirilmiştir.

- `lib/core`: Servis arayüzleri ve yardımcı sınıflar (Location servisleri vb.).
- `lib/data`: Veri modelleri ve repository implementasyonları.
- `lib/presentation`: UI ekranları, ViewModel sınıfları ve widget'lar.

**Kullanılan Ana Paketler:** `provider`, `firebase_auth`, `cloud_firestore`, `geolocator`, `image_picker`, `shared_preferences`.

## Kurulum ve Çalıştırma

1.  Bağımlılıkları yükleyin:
    ```bash
    flutter pub get
    ```
2.  Uygulamayı çalıştırın:
    ```bash
    flutter run
    ```

**Not:** Gerçek konum servislerini kullanmak için `main.dart` dosyasında `MockLocationService` yerine `GeolocatorLocationService` kullanıldığından emin olun.

## Gerekli İzinler

Uygulamanın tam fonksiyonlu çalışması için aşağıdaki izinlerin yapılandırılması gerekir:

**Android (`android/app/src/main/AndroidManifest.xml`):**

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS (`ios/Runner/Info.plist`):**

- `NSLocationWhenInUseUsageDescription`: "Uygulama yakınındaki semt pazarlarını bulmak için konumunuza erişim gereklidir."

## Dosya Yapısı ve Eklenenler

- **Ekranlar:**
  - `search_screen.dart`: Ürün arama ekranı.
  - `report_list_screen.dart` & `report_form_screen.dart`: Bildirim listeleme ve oluşturma.
  - `account_screen.dart`: Profil ve ayarlar yönetimi.
- **Modeller:**
  - `Market` modeli `products` ve `occupancyPercentage` alanlarını içerir.
