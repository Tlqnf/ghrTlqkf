import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';

class FcmApiService {
  // patch - users/me/fcm-token
  // 사용자 FCM 토큰을 업데이트
  static Future<void> updateUserFcmToken(_token, fcmToken) async {
    final fcmResponse = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/me/fcm-token'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    if (fcmResponse.statusCode == 200) {
      debugPrint('FCM token sent to server successfully.');
    } else {
      debugPrint('Failed to send FCM token to server: ${fcmResponse.statusCode}');
      debugPrint('Response body: ${fcmResponse.body}');
    }
  }
}