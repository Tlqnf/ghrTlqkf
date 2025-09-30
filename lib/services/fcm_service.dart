import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

// Background message handler must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: \${message.messageId}");
  debugPrint('Message data: \${message.data}');
  debugPrint('Message notification: \${message.notification?.title}');
  debugPrint('Message notification: \${message.notification?.body}');
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> initialize() async {
    // Request permission for iOS and Android 13+
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get the FCM token (for debugging/logging purposes within the service)
    final String? fcmToken = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $fcmToken");

    // Set up the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: \${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: \${message.notification}');
      }
    });

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // You can navigate to a specific screen based on the message data
    });
  }

  @pragma('vm:entry-point')
  Future<void> backgroundMessageHandler(RemoteMessage remote) async{
    debugPrint("background message $remote");
  }
}