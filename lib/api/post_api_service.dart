import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/post.dart';

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
