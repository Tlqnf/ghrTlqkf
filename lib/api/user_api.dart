import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/analyze.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/models/user.dart';
import 'package:image_picker/image_picker.dart';

class UserApi {
  // get - users/me
  // 사용자 프로필 조회 (완)
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

  // get - users/{userId}
  // 사용자 조회 (게시글 표시용)
  static Future<User> getUserById(String token, int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/$userId'),
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
  // 사용자 프로필 수정 (완)
  static Future<void> updateUserProfile({
    required String token,
    required String username,
    required String profileDescription,
    XFile? profilePicFile,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/me');
    final request = http.MultipartRequest('PATCH', uri);

    request.headers['Authorization'] = 'Bearer $token';

    final userData = {
      'username': username,
      'profile_description': profileDescription,
    };
    request.fields['user_data'] = jsonEncode(userData);

    if (profilePicFile != null) {
      final file = await http.MultipartFile.fromPath(
        'profile_pic_file',
        profilePicFile.path,
      );
      request.files.add(file);
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to update user profile: ${response.statusCode} $responseBody');
    }
  }

  // get - users/mention/check
  // 유저 멘션 여부 (완)
  static Future<bool?> checkUserMention(String user, String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/users/mention/check?user=$user"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-type": "application/json",
      }
    );

    if (response.statusCode == 200) {
      return bool.parse(response.body);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // get - users/me/profile-description-status
  // 유저의 프로필 중 설명이 있는가? (완)
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
  // 유저 로그아웃 (완)
  static Future<void> logoutUserProfile(String token) async {
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

  // delete - users/me
  // 유저 회원 탈퇴 (완)
  static Future<void> deleteUserProfile(String token) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 204) {
      return;
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // get - report/weekly_summary
  // 유저의 주간 기록 표시 (완)
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
  // 유저가 최근 작성한 4개 게시글 목록 반환 (완)
  static Future<List<Post>> getRecentPosts(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/post/me/posts/recent'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

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

  // get - post/me/posts?page={}
  // 유저가 작성한 모든 게시글 반환 (완)
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
  // 유저가 최근에 북마크한 4개 게시글 목록 반환 (완)
  static Future<List<Post>> getRecentBookmarks(String token) async {
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
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format (not a List)');
      }
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // get - post/me/bookmarked?page={}
  // 유저가 북마크한 모든 게시글 반환
  static Future<List<Post>> getBookmarks(String token, int page) async {
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
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format (not a List)');
      }
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }
}