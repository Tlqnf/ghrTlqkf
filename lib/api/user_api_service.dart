import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;
import 'package:pedal/models/analyze.dart';
import '../models/user.dart';

class UserApiService {
  static const String _baseUrl = 'http://172.30.1.14:8080';

  static Future<User> fetchUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  static Future<Bool> checkUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/profile-description-status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  static void logoutUserProfile(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/me/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  static Future<Analyze> analyzeUser(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/report/weekly_summary'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Analyze.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }


  }
}
