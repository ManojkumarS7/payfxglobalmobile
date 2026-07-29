import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // static Future<void> initialize() async {
  //   await _requestPermission();
  //   await _initLocalNotification();
  //   await _createAndroidChannel();
  //   await _listenForegroundNotification();
  //   await _printFcmToken();
  // }

  static Future<void> initialize() async {
    await _requestPermission();

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initLocalNotification();
    await _createAndroidChannel();
    await _listenForegroundNotification();
    await _printFcmToken();
  }

  static Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _initLocalNotification() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: settings);
  }

  static Future<void> _createAndroidChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'payfx_channel',
      'PayFX Notifications',
      description: 'PayFX Global notification channel',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _listenForegroundNotification() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("========== FCM RECEIVED ==========");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      print("Data: ${message.data}");

      await _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("========== NOTIFICATION CLICKED ==========");
      print("Data: ${message.data}");
    });
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'PayFX Global';
    final body = message.notification?.body ?? 'You have a new update';

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'payfx_channel',
      'PayFX Notifications',
      channelDescription: 'PayFX Global notification channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  static Future<void> _printFcmToken() async {
    final apnsToken = await _firebaseMessaging.getAPNSToken();
    print("APNS TOKEN:");
    print(apnsToken);

    final token = await _firebaseMessaging.getToken();
    print("FCM TOKEN:");
    print(token);

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("NEW FCM TOKEN:");
      print(newToken);
    });
  }
}
