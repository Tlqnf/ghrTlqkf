import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';

class OauthLoginApi {
  static Future<String?> sendTokenGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/oauth/google/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)["access_token"];
      }
    } catch (e) {
      throw Exception("서버 통신 실패 $e");
    }
    return null;
  }

  static Future<String?> sendTokenKakao(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/oauth/kakao/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': accessToken}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)["access_token"];
      }
    } catch (e) {
      throw Exception("서버 통신 실패 $e");
    }
    return null;
  }
}
