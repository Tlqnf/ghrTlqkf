
import 'package:http/http.dart' as http;
import 'dart:convert'; // Add for JSON encoding
import '../models/comment.dart'; // Import the new Comment model

final BASE_URI = "http://172.30.1.14:8080";

class PostApiService{

}

class CommentApiService{
  Future<void> getPostComments(String token, int postId) async {
    dynamic response = await http.get(
        Uri.parse("${BASE_URI}/post/${postId}/comments"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
    );
  }

  Future<void> getPostChildComments(int commentId, String token) async{
    dynamic response = await http.get(
        Uri.parse("${BASE_URI}/post/comments/${commentId}"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
    );
  }

  // 댓글 등록 (POST /post/{post_id}/comments)
  Future<void> createComment(
      String token,
      Comment comment // Comment 모델을 직접 받도록 변경
      ) async {
    final url = Uri.parse("${BASE_URI}/post/${comment.postId}/comments");
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
    print('Create Comment Response Status: ${response.statusCode}');
    print('Create Comment Response Body: ${response.body}');
  }

  // 댓글 업데이트 (PATCH /post/comments/{comment_id})
  Future<void> updateComment(
      String token,
      int commentId,
      String content,
      {List<String>? mentions} // mentions 추가
      ) async {
    final url = Uri.parse("${BASE_URI}/post/comments/${commentId}");
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
    print('Update Comment Response Status: ${response.statusCode}');
    print('Update Comment Response Body: ${response.body}');
  }
}