import 'dart:convert';

import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/notice.dart';
import 'package:http/http.dart' as http;

class NoticeApi {
  static Future<List<Notice>> getNotices(limit, String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/notices"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Notice.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load notice ${response.statusCode}');
    }
  }

  static Future<Notice> getNotice(String noticeId, String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/notices/$noticeId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return Notice.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load notice ${response.statusCode}');
    }
  }
}