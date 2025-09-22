import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/models/comment.dart';

class PostApiService {
  // get - post
  // 게시글 목록 수집
  static Future<List<Post>> getPosts(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/post'),
      headers: {
        'Authorization': 'Bearer $token',
      },
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
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  // patch - post (수정 필요 createPost와 똑같은 구조)
  // 게시글 수정
  static Future<http.Response> updatePost(UpdatePost postData, String token) {
    try {
      final response = http.post(
        Uri.parse("${ApiConfig.baseUrl}/post/${postData.postId}"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-type': 'application/json'
        },
        body: jsonEncode({
          'title': postData.title,
          'content': postData.content,
        })
      );
      return response;

    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  // delete - post/{postId}
  // 게시글 삭제
  static Future<http.Response> deletePost(int postId, String token) {
    try {
      final response = http.delete(
        Uri.parse('${ApiConfig.baseUrl}/post/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-type': "application/json"
        }
      );
      return response;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  // post - post/{postId}/post-like
  // 게시글 좋아요
  static Future<void> addThumbsUp(String token, int postId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/post/$postId/post-like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('like failed: ${res.statusCode}');
    }
  }

  // post - post/{postId}/post-unlike
  // 게시글 좋아요 취소
  static Future<void> removeThumbsUp(String token, int postId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/post/$postId/post-unlike'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('unlike failed: ${res.statusCode}');
    }
  }

  // post - post/{postId}/bookmark
  // 게시글 북마크 추가

  // delete - post/{postId}/bookmark
  // 게시글 북마크 삭제
}

class CommentApiService{
  // get - post/{postId}/comments
  // 댓글 리스트 표시
  static Future<void> getPostComments(String token, int postId) async {
    dynamic response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/post/$postId/comments"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
    );
  }

  // get - post/comments/{commentId}
  // 대댓글 리스트 표시
  static Future<void> getPostChildComments(int commentId, String token) async {
    dynamic response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/post/comments/$commentId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
    );
  }

  // post - post/{post_id}/comments
  // 댓글 작성하기
  static Future<void> createComment(String token, Comment comment) async {
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

  // patch - post/comments/{commentId}
  // 댓글 수정하기
  static Future<void> updateComment(String token, int commentId, String content, {List<String>? mentions}) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/post/comments/$commentId");
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

  // delete - post/comments/{commentId}
  // 댓글 삭제하기

  // post - post/{commentId}/comment-like
  // (대)댓글 좋아요

  // post - post/{commentId}/comment-unlike
  // (대)댓글 좋아요 취소
}