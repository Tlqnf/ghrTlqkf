import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';

class RouteApiService {
  static Future<void> updateRoute(
      String routeName, List<String>? tagList, String token, int routeId) async {
    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/routes/${routeId}"),
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
      throw Exception('Failed to update route: ${response.statusCode}');
    }
  }
}