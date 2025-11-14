import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/post.dart';

class PostApi {
  // get - post
  // 게시글 목록 수집 (완)
  static Future<List<Post>> getPosts(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/post'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  // post - post (수정 필요 반환값)
  // 게시글 만들기 (실질적인 리스트 표시)
  static Future<bool> createPost(
    String postData,
    String? mapImagePath,
    List<String> imagePaths,
    String token,
  ) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}/post');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add post data field
      request.fields['post_data'] = postData;

      if (mapImagePath != null && mapImagePath.isNotEmpty) {
        File mapImageFile = File(mapImagePath);
        var stream = http.ByteStream(mapImageFile.openRead());
        var length = await mapImageFile.length();
        var multipartFile = http.MultipartFile(
          'map_image',
          stream,
          length,
          filename: basename(mapImageFile.path),
        );
        request.files.add(multipartFile);
      }

      // Add images to the request
      for (String path in imagePaths) {
        if (path.isNotEmpty) {
          File imageFile = File(path);
          var stream = http.ByteStream(imageFile.openRead());
          var length = await imageFile.length();
          var multipartFile = http.MultipartFile(
            'images', // FastAPI endpoint's expected field name for files
            stream,
            length,
            filename: basename(imageFile.path),
          );
          request.files.add(multipartFile);
        }
      }

      // Send the request
      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        debugPrint("저장 성공 ${response.statusCode}");
        return true;
      } else {
        debugPrint("저장 실패 ${response.statusCode}");
        return false;
      }
    } catch (e) {
      // You might want to handle exceptions more gracefully
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  // patch - post (수정 필요 createPost와 똑같은 구조)
  // 게시글 수정
  static Future<bool> updatePost(
    String postData,
    int postId,
    List<String> imagePaths,
    String token,
  ) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}/post/$postId');
      var request = http.MultipartRequest('PATCH', uri);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Post data
      request.fields['post_update'] = postData;

      // 새로 추가된 이미지 파일 첨부
      for (String path in imagePaths) {
        if (path.isNotEmpty) {
          File imageFile = File(path);
          var stream = http.ByteStream(imageFile.openRead());
          var length = await imageFile.length();
          var multipartFile = http.MultipartFile(
            'new_images',
            stream,
            length,
            filename: basename(imageFile.path),
          );
          request.files.add(multipartFile);
        }
      }

      // Send request
      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  // delete - post/{postId}
  // 게시글 삭제 (완)
  static Future<http.Response> deletePost(int postId, String token) {
    try {
      final response = http.delete(
        Uri.parse('${ApiConfig.baseUrl}/post/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-type': "application/json",
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // post - post/{postId}/post-like
  // 게시글 좋아요 (완)
  static Future<void> addThumbsUp(String token, int postId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/post/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('like failed: ${res.statusCode}');
    }
  }

  static Future<bool> checkThumbsUp(String token, int postId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/post/$postId/is_liked"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)["is_liked"];
    } else {
      throw Exception("좋아요 호출 실패");
    }
  }

  // post - post/{postId}/bookmark
  // 게시글 북마크 추가 (완)
  static Future<void> addBookmark(String token, int postId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/post/$postId/bookmark'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'postId': postId}),
    );
    if (res.statusCode != 204) {
      throw Exception('add bookmark failed: ${res.statusCode}');
    }
  }

  // delete - post/{postId}/bookmark
  // 게시글 북마크 삭제 (완)
  static Future<void> removeBookmark(String token, int postId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/post/$postId/bookmark'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'postId': postId}),
    );
    if (res.statusCode != 204) {
      throw Exception('delete bookmark failed: ${res.statusCode}');
    }
  }

  static Future<bool> checkBookmark(String token, int postId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/post/$postId/is-bookmarked"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)["is_bookmarked"];
    } else {
      throw Exception("좋아요 호출 실패");
    }
  }
}
