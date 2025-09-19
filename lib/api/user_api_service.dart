import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pedal/models/analyze.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../models/card.dart';

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

  static Future<bool?> checkUserProfile(String token) async{
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/profile-description-status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      return json['is_null'];

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

  static Future<List<CardSummary>> getRecentCard(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/post/me/posts/recent'),
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

  static Future<List<CardSummary>> getRecentBookmarkCard(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/post/me/bookmarked/recent'),
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

  static Future<List<Post>> getRecentTenCard(String token, int page) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/post/me/posts?page=${page}&page_size=10'),
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

  static Future<void> addThumbsUp(String token, int postId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/post/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('like failed: ${res.statusCode}');
    }
  }

  static Future<void> removeThumbsUp(String token, int postId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/post/$postId/unlike'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('unlike failed: ${res.statusCode}');
    }
  }

}

