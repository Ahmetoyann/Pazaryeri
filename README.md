# Flutter Application 1

## Pazaryeri App — Mimari & Nasıl Geliştirilmeli

* [ ]

- lib/core: Servis arayüzleri ve location servisleri (mock ve geolocator)
- lib/data: Model ve repository arayüzleri/implementasyonları (Mock repository yüklü)
- lib/presentation: UI, viewmodel ve bileşenler

Kullanılan ana paketler: `provider`, `geolocator` (opsiyonel), `geocoding` (opsiyonel)

Çalıştırma noktası: `lib/main.dart`

Hızlı başlatma:

1. `flutter pub get` çalıştırın
2. Emulatör/cihazda çalıştırın: `flutter run`

Geçiş: Gerçek konum servislerini kullanmak için `main.dart` dosyasında `MockLocationService` yerine `GeolocatorLocationService` oluşturun ve gerekli Android/iOS izinlerini eklemeyi unutmayın.

Permissions (Android/iOS) notları:
- Android: `android/app/src/main/AndroidManifest.xml` içinde aşağıdaki izinleri ekleyin:
	- `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />`
	- `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />`
- iOS: `ios/Runner/Info.plist` içine şu anahtarları ekleyin:
	- `NSLocationWhenInUseUsageDescription` — "Uygulama yakınındaki semt pazarlarını bulmak için konumunuza erişim gereklidir"

Kişiselleştirme & genişletme önerileri:
- Repository sınıfını gerçek bir HTTP servise bağlayın veya Firebase Firestore kullanın.
- Unit/integration testleri ekleyin (viewmodel/unit tests).
- Kullanıcı konumunu güncellemek için bir refresh düğmesi veya sürekli güncelleme seçeneği ekleyin.


# flutter_application_1

A new Flutter project.

Eklenen özellikler:
- Alt kısmında 4 ana buton (PAZARYERİ, ARA, DOLULUK, BİLDİR) ile tab gezintisi.
- `ARA` sayfasında ürün ismi girilerek, o ürünü satan pazaryerleri listelenir; tıklanınca adres gösterilir.
- `DOLULUK` sayfasında pazaryerlerinin doluluk oranı (yüzdelik) gösterilir; tıklayınca adres gösterilir.
- `BİLDİR` sayfasında tüm pazaryerleri listelenir; birine tıklanarak şikayet/bildirim formu açılır ve gönderildiğinde onay Snackbar'ı görünür.

Eklenen dosyalar:
- `lib/presentation/screens/search_screen.dart`
- `lib/presentation/screens/occupancy_screen.dart`
- `lib/presentation/screens/report_list_screen.dart`
- `lib/presentation/screens/report_form_screen.dart`

Model güncellemeleri:
- `Market` modeline `products` ve `occupancyPercentage` alanları eklendi.

