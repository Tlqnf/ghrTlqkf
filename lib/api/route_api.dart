import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';

class RouteApi {
  // get - start-session
  // route id 받기
  static Future<int> getRouteId(String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/start-session"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      }
    );
    if (response.statusCode == 200) {
      debugPrint("${jsonDecode(response.body)["route_id"]}");
      return jsonDecode(response.body)["route_id"];
    } else {
      throw Exception("라우터 ID 생성 실패: ${jsonDecode(response.body)}");
    }
  }

  // patch - routes/{routeId}
  // 경로 이름 or 태그 수정 todo
  static Future<void> updateRoute(String routeName, List<String>? tagList, String token, int routeId) async {
    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/routes/$routeId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": routeName,
        "tags": tagList ?? [],
      })
    );

    if (response.statusCode == 200) {
      return ;
    } else {
      throw Exception('Failed to update route: ${response.body}');
    }
  }

  // get - routes/me?page={}&page_size={}
  // 사용자의 경로 가져오기 todo
  static Future<void> getMyRoutes(String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/routes/me"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to load my routes: ${response.statusCode}');
    }
  }

  // get - routes/{routeId}
  // 경로 아이디를 통해 가져오기 todo
  static Future<void> getRouteById(String token, String routeId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/routes/$routeId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to load route: ${response.statusCode}');
    }
  }

  // get - routes
  // 모든 경로 목록 표시 todo
  static Future<void> getRoutesByFilter(List<String> tags, String token) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/routes").replace(
      queryParameters: {
        'tags': tags,
      },
    );
    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception(
          'Failed to load routes by filter: ${response.statusCode}');
    }
  }
}