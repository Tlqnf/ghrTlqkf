import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/route.dart';

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
      return jsonDecode(response.body)["route_id"];
    } else {
      throw Exception("라우터 ID 생성 실패: ${jsonDecode(response.body)}");
    }
  }

  // patch - routes/{routeId}
  // 경로 이름 or 태그 수정
  static Future<void> updateRoute(UpdateRoute routeData, int routeId, String token) async {
    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/routes/$routeId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(routeData.toJson())
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
  // 경로 아이디를 통해 가져오기
  static Future<List<dynamic>> getRouteById(int routeId, String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/routes/$routeId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["points_json"];
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

  static Future<List<dynamic>> getRoutePoint(int routeId, String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/routes/$routeId/turn-points"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load navigator route: ${response.body}');
    }
  }
}