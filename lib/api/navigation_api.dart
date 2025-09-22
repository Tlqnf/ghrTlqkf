import 'dart:convert';

import 'package:pedal/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:pedal/models/route.dart';

class NavigationApi {
  // post - navigation/guide-route
  // routeId로 네비게이션
  static Future<String> guideRoute(int routeId, String token) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/navigation/guide-route"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "route_id": routeId
      })
    );
    if (response.statusCode == 200) {
      return "경로 제공";
    } else {
      throw Exception('Failed to load navigator route: ${response.statusCode}');
    }
  }

  // post - navigation/guide-destination
  // 시작, 도착 좌표로 네비게이션
  static Future<String> guideDestination(GuideRoute location, String token) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/navigation/guide-destination"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(location.toJson()),
    );

    if (response.statusCode == 200) {
      return "경로 제공";
    } else {
      throw Exception('Failed to load navigator route: ${response.statusCode}');
    }
  }
}