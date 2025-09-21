import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

// Background message handler must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp(); // Not needed if you just handle the notification data

  print("Handling a background message: \${message.messageId}");
  print('Message data: \${message.data}');
  print('Message notification: \${message.notification?.title}');
  print('Message notification: \${message.notification?.body}');
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

    // Get the FCM token
    final String? token = await _firebaseMessaging.getToken();
    print("FCM Token: \$token");

    // Set up the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: \${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: \${message.notification}');
      }
    });

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // You can navigate to a specific screen based on the message data
    });
  }


  Future<void> updateUserFcmToken(_token, fcmToken) async {
    final fcmResponse = await http.patch(
      Uri.parse('http://172.30.1.14:8080/users/me/fcm-token'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    if (fcmResponse.statusCode == 200) {
      print('FCM token sent to server successfully.');
    } else {
      print('Failed to send FCM token to server: ${fcmResponse.statusCode}');
      print('Response body: ${fcmResponse.body}');
    }
  }

  @pragma('vm:entry-point')
  Future<void> backgroundMessageHandler(RemoteMessage remote) async{
    print("background message ${remote}");
  }
}
