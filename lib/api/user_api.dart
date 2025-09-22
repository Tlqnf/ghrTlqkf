import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/analyze.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/models/user.dart';
import 'package:pedal/models/card.dart';

class UserApiService {
  // get - users/me
  static Future<User> fetchUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
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

  // patch - users/me

  // get - users/mention/check

  // get - users/me/profile-description-status
  static Future<bool?> checkUserProfile(String token) async{
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me/profile-description-status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      return json["is_null"];

    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // post - users/me/logout
  static void logoutUserProfile(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/me/logout'),
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

  // get - report/weekly_summary
  static Future<Analyze> analyzeUser(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/weekly_summary'),
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

  // get - post/me/posts/recent
  static Future<List<CardSummary>> getRecentPosts(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/post/me/posts/recent'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // 응답이 List<Map<String, dynamic>> 형태라고 가정
      if (decoded is List) {
        return decoded
            .map((e) => CardSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format (not a List)');
      }
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // get - post/me/posts?page={}
  static Future<List<Post>> getPosts(String token, int page) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/post/me/posts?page=$page&page_size=10'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // 응답이 List<Map<String, dynamic>> 형태라고 가정
      if (decoded is List) {
        return decoded
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format (not a List)');
      }
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // get - post/me/bookmarked/recent
  static Future<List<CardSummary>> getRecentBookmarks(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/post/me/bookmarked/recent'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // 응답이 List<Map<String, dynamic>> 형태라고 가정
      if (decoded is List) {
        return decoded
            .map((e) => CardSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format (not a List)');
      }
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // get - post/me/bookmarked?page={}
  static Future<List<CardSummary>> getBookmarks(String token, int page) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/post/me/bookmarked?page=$page&page_size=10'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // 응답이 List<Map<String, dynamic>> 형태라고 가정
      if (decoded is List) {
        return decoded
            .map((e) => CardSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format (not a List)');
      }
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }
}