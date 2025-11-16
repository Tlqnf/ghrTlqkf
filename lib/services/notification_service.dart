import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'pedal_recording_channel';
  static const String _channelName = 'Pedal Recording';
  static const String _channelDescription =
      'Notification for ongoing ride recording.';

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Assuming default launcher icon

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low, // Low importance to be less intrusive
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> showRecordingNotification({
    required String time,
    required String distance,
    required String speed,
  }) async {
    final AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes the notification persistent
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      subText: '주행 기록 중...',
      styleInformation: BigTextStyleInformation(
        '<strong>시간:</strong> $time <br/> <strong>거리:</strong> $distance <br/> <strong>속도:</strong> $speed',
        htmlFormatBigText: true,
      ),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'PEDAL 주행 기록',
      '시간: $time | 거리: $distance | 속도: $speed',
      platformChannelSpecifics,
    );
  }

  Future<void> cancelNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(0); // Notification ID
  }
}
