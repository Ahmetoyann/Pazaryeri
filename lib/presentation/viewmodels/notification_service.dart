import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

    // Android 13+ için bildirim izni iste
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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
}
