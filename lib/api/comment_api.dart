import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/comment.dart';

class CommentApiService{
  // get - post/{postId}/comments
  // 댓글 리스트 표시
  static Future<List<Comment>> getPostComments(String token, int postId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/post/$postId/comments"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments for post $postId: ${response.statusCode}');
    }
  }

  // get - post/comments/{commentId}/Replies
  // 대댓글 리스트 표시
  static Future<List<Reply>> getCommentReplies(int commentId, String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/post/comments/$commentId/replies"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Reply.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load replies for comment $commentId: ${response.statusCode}');
    }
  }

  // post - post/{post_id}/comments
  // 댓글 작성하기
  static Future<void> createComment(String token, CreateComment comment) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/post/${comment.postId}/comments"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(comment.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('create comment failed: $response');
    }
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

    if (response.statusCode != 200) {
      throw Exception('update comment failed: $response');
    }
  }

  // delete - post/comments/{commentId}
  // 댓글 삭제하기
  static Future<void> deleteComment(String token, int postId, int commentId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/post/comments/$commentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'postId': postId,
        'commentId': commentId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('delete comment failed: ${res.statusCode}');
    }
  }

  // post - post/{commentId}/comment-like
  // (대)댓글 좋아요
  static Future<void> likeComment(String token, int postId, int commentId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/post/comments/$commentId/comment-like'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'postId': postId,
        'commentId': commentId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('like comment failed: ${res.statusCode}');
    }
  }

  // post - post/{commentId}/comment-unlike
  // (대)댓글 좋아요 취소
  static Future<void> unlikeComment(String token, int postId, int commentId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/post/comments/$commentId/comment-unlike'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'postId': postId,
        'commentId': commentId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('unlike comment failed: ${res.statusCode}');
    }
  }
}