// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
//
// class FirebaseService {
//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   static String? _fcmToken;
//
//   /// Initialize Firebase
//   static Future<void> initialize() async {
//     try {
//       // Check if Firebase is already initialized
//       if (Firebase.apps.isEmpty) {
//         await Firebase.initializeApp();
//         if (kDebugMode) {
//           print('✅ Firebase initialized successfully');
//         }
//       } else {
//         if (kDebugMode) {
//           print('ℹ️ Firebase already initialized');
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Firebase initialization error: $e');
//       }
//     }
//   }
//
//   /// Request notification permissions
//   static Future<void> requestPermission() async {
//     try {
//       NotificationSettings settings = await _messaging.requestPermission(
//         alert: true,
//         announcement: false,
//         badge: true,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//         sound: true,
//       );
//
//       if (kDebugMode) {
//         print(
//           '✅ Notification permission status: ${settings.authorizationStatus}',
//         );
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Permission request error: $e');
//       }
//     }
//   }
//
//   /// Get FCM token
//   static Future<String?> getToken() async {
//     try {
//       // Add delay to ensure Firebase is fully initialized
//       await Future.delayed(const Duration(seconds: 2));
//       _fcmToken = await _messaging.getToken();
//       if (kDebugMode) {
//         if (_fcmToken != null) {
//           print('✅ FCM Token: $_fcmToken');
//         } else {
//           print(
//             '⚠️ FCM Token is null - Google Play Services may not be available',
//           );
//         }
//       }
//       return _fcmToken;
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error getting FCM token: $e');
//         print(
//           '💡 Note: This may happen if Google Play Services is not available on the device',
//         );
//       }
//       return null;
//     }
//   }
//
//   /// Get cached FCM token
//   static String? get cachedToken => _fcmToken;
//
//   /// Listen to token refresh
//   static void onTokenRefresh(Function(String) callback) {
//     _messaging.onTokenRefresh.listen((newToken) {
//       _fcmToken = newToken;
//       callback(newToken);
//       if (kDebugMode) {
//         print('🔄 FCM Token refreshed: $newToken');
//       }
//     });
//   }
//
//   /// Handle foreground messages
//   static void onForegroundMessage(Function(RemoteMessage) callback) {
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       if (kDebugMode) {
//         print('📩 Foreground message received: ${message.notification?.title}');
//       }
//       callback(message);
//     });
//   }
//
//   /// Handle background messages (must be top-level function)
//   static Future<void> _firebaseMessagingBackgroundHandler(
//     RemoteMessage message,
//   ) async {
//     // Initialize Firebase only if not already initialized
//     if (Firebase.apps.isEmpty) {
//       await Firebase.initializeApp();
//     }
//     if (kDebugMode) {
//       print('📩 Background message received: ${message.notification?.title}');
//     }
//   }
//
//   /// Setup background message handler
//   static void setupBackgroundHandler() {
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   }
//
//   /// Handle notification tap when app is opened from terminated state
//   static void onMessageOpenedApp(Function(RemoteMessage) callback) {
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       if (kDebugMode) {
//         print(
//           '📱 App opened from notification: ${message.notification?.title}',
//         );
//       }
//       callback(message);
//     });
//   }
//
//   /// Get initial message (if app was opened from notification)
//   static Future<void> getInitialMessage(
//     Function(RemoteMessage) callback,
//   ) async {
//     RemoteMessage? initialMessage = await FirebaseMessaging.instance
//         .getInitialMessage();
//     if (initialMessage != null) {
//       if (kDebugMode) {
//         print(
//           '📱 App launched from notification: ${initialMessage.notification?.title}',
//         );
//       }
//       callback(initialMessage);
//     }
//   }
//
//   /// Complete Firebase setup with all listeners
//   static Future<void> setupPushNotifications({
//     Function(RemoteMessage)? onForegroundMessageReceived,
//     Function(RemoteMessage)? onNotificationTap,
//     Function(RemoteMessage)? onAppLaunchedFromNotification,
//     Function(String)? onTokenRefreshed,
//   }) async {
//     // Request permission
//     await requestPermission();
//
//     // Get FCM token
//     await getToken();
//
//     // Setup background handler
//     setupBackgroundHandler();
//
//     // Listen to foreground messages
//     if (onForegroundMessageReceived != null) {
//       onForegroundMessage(onForegroundMessageReceived);
//     }
//
//     // Listen to notification taps
//     if (onNotificationTap != null) {
//       onMessageOpenedApp(onNotificationTap);
//     }
//
//     // Check if app was launched from notification
//     if (onAppLaunchedFromNotification != null) {
//       await getInitialMessage(onAppLaunchedFromNotification);
//     }
//
//     // Listen to token refresh
//     if (onTokenRefreshed != null) {
//       onTokenRefresh(onTokenRefreshed);
//     }
//
//     if (kDebugMode) {
//       print('✅ Push notifications setup complete');
//     }
//   }
//
//   /// Send FCM token to your backend
//   static Future<void> sendTokenToBackend(String token, String userId) async {
//     try {
//       // TODO: Send token to your backend API
//       // Example:
//       // await http.post(
//       //   Uri.parse('YOUR_API_URL/save-fcm-token'),
//       //   headers: {'Content-Type': 'application/json'},
//       //   body: jsonEncode({'user_id': userId, 'fcm_token': token}),
//       // );
//       if (kDebugMode) {
//         print('📤 Sending token to backend: $token for user: $userId');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error sending token to backend: $e');
//       }
//     }
//   }
// }
