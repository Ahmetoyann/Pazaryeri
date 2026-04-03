import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';

// Arka plan mesaj işleyicisi (Top-level function olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda gelen mesajları burada işleyebilirsiniz
  print("Arka plan bildirimi alındı: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Bildirim tıklamalarını dinlemek için bir yayın akışı (Stream)
  final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  // Uygulama kapalıyken açılışta gelen payload'ı tutmak için
  String? launchPayload;

  NotificationService._internal();

  Future<void> init() async {
    // Android için varsayılan ikon ayarı (@mipmap/ic_launcher varsayılan uygulama ikonudur)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS için ayarlar
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // Uygulama bildirimden mi açıldı kontrol et (Terminated State)
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      launchPayload =
          notificationAppLaunchDetails?.notificationResponse?.payload;
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        // Bildirime tıklandığında payload'ı stream'e ekle
        selectNotificationStream.add(notificationResponse.payload);
      },
    );

    // FCM Başlatma ve İzin İsteme
    await _initFCM();

    // Android 13+ için bildirim izni iste
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Bildirim izni iste
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Uygulama ön plandayken (Foreground) gelen bildirimleri dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Eğer bildirim içeriği varsa yerel bildirim olarak göster
      if (notification != null && android != null) {
        // Payload oluşturma: ID bilgisini ekle
        String payload = message.data['type'] ?? message.data['payload'] ?? '';

        if (payload == 'question_reply' && message.data['questionId'] != null) {
          payload += ':${message.data['questionId']}';
        } else if (payload == 'review_reply' &&
            message.data['reviewId'] != null) {
          payload += ':${message.data['reviewId']}';
        }

        showNotification(
          id: notification.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: payload,
        );
      }
    });

    // Token yenilendiğinde (örn: uygulama yeniden yüklendiğinde) veritabanını güncelle
    messaging.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Email parametresi AuthService içinde kullanılmıyor (uid kullanılıyor) ama imza gereği veriyoruz
        await AuthService.instance
            .updateUserInDb({'fcmToken': newToken}, user.email ?? '');
      }
    });
  }

  // Cihazın FCM Token'ını al
  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload, // Tıklama aksiyonu için veri taşıyıcı
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'market_channel_id',
      'Pazar Bildirimleri',
      channelDescription: 'Favori pazarlarınız açıldığında bildirim alırsınız',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Backend (Cloud Functions) kullanmadan doğrudan cihazdan cihaza bildirim göndermek için.
  /// Not: Bu yöntem için Firebase Konsolundan 'Cloud Messaging API (Legacy)' etkinleştirilmeli
  /// ve Server Key alınmalıdır.
  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Firebase Console -> Project Settings -> Cloud Messaging -> Cloud Messaging API (Legacy)
      // Buraya kendi Server Key'inizi yapıştırın
      const String serverKey = 'BURAYA_SERVER_KEY_YAZINIZ';

      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{'body': body, 'title': title},
            'priority': 'high',
            'data': data ??
                <String, dynamic>{'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
            'to': fcmToken,
          },
        ),
      );
    } catch (e) {
      print("Bildirim gönderme hatası: $e");
    }
  }
}
