import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/models/comment.dart';

class PostApiService {
  static Future<http.Response> createPost(
      String postData, List<String> imagePaths, String token) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}/post');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add post data field
      request.fields['post_data'] = postData;

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

      var response = await http.Response.fromStream(streamedResponse);
      return response;
    } catch (e) {
      // You might want to handle exceptions more gracefully
      print('Error creating post: $e');
      rethrow;
    }
  }

  static Future<http.Response> updatePost(UpdatePost postData, String token) {
    try {
      final response = http.post(
        Uri.parse("${ApiConfig.baseUrl}/post/${postData.postId}"),
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-type': 'application/json'
        },
        body: jsonEncode({
          'title': postData.title,
          'content': postData.content,
        })
      );
      return response;

    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  static Future<http.Response> deletePost(int postId, String token) {
    try {
      final response = http.delete(
        Uri.parse('${ApiConfig.baseUrl}/post/${postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-type': "application/json"
        }
      );
      return response;
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }
}

class CommentApiService{
  Future<void> getPostComments(String token, int postId) async {
    dynamic response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/post/${postId}/comments"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
    );
  }

  Future<void> getPostChildComments(int commentId, String token) async {
    dynamic response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/post/comments/${commentId}"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
    );
  }

  // 댓글 등록 (POST /post/{post_id}/comments)
  Future<void> createComment(String token, Comment comment) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/post/${comment.postId}/comments");
    final body = jsonEncode(comment.toJson()); // Comment 모델을 JSON으로 변환

    dynamic response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // TODO: 응답 처리 (예: 상태 코드 확인, 에러 처리)
    debugPrint('Create Comment Response Status: ${response.statusCode}');
    debugPrint('Create Comment Response Body: ${response.body}');
  }

  // 댓글 업데이트 (PATCH /post/comments/{comment_id})
  Future<void> updateComment(
      String token, int commentId, String content, {List<String>? mentions}) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/post/comments/${commentId}");
    final body = jsonEncode({
      "content": content,
      "mentions": mentions ?? [], // body에도 mentions 추가
    });

    dynamic response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // TODO: 응답 처리 (예: 상태 코드 확인, 에러 처리)
    debugPrint('Update Comment Response Status: ${response.statusCode}');
    debugPrint('Update Comment Response Body: ${response.body}');
  }
}