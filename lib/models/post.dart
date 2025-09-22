import 'dart:convert';

class Post {
  final int id;
  final String title;
  final String content;
  final int likeCount;
  final int readCount;
  final int userId;
  final DateTime createdAt;
  final List<String> images;
  final String mapImageUrl;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.likeCount,
    required this.readCount,
    required this.userId,
    required this.createdAt,
    required this.images,
    required this.mapImageUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final imgs = (json['images'] as List?)
        ?.map((e) => e is String ? e : (e?['url'] as String? ?? ''))
        .where((s) => s.isNotEmpty)
        .toList() ?? <String>[];

    return Post(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      likeCount: json['like_count'] ?? 0,
      readCount: json['read_count'] ?? 0,
      userId: json['user_id'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toLocal() ?? DateTime.now(),
      images: imgs,
      mapImageUrl: json['map_image_url'] ?? '',
    );
  }
}

class CreatePost {
  final String title;
  final String content;
  final int? reportId;
  final List<String> hashTag;
  final bool public;
  final double? speed;
  final double? distance;
  final double? time; // in seconds

  CreatePost({
    required this.title,
    required this.content,
    this.reportId,
    required this.hashTag,
    required this.public,
    this.speed,
    this.distance,
    this.time,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'content': content,
      'hash_tag': hashTag,
      'public': public,
    };
    // Add optional fields only if they are not null
    if (reportId != null) data['report_id'] = reportId;
    if (speed != null) data['speed'] = speed;
    if (distance != null) data['distance'] = distance;
    if (time != null) data['time'] = time;
    return data;
  }

  String toJsonString() => json.encode(toJson());
}

class UpdatePost {
  final int postId;
  final String title;
  final String content;

  UpdatePost({
    required this.postId,
    required this.title,
    required this.content,
  });
}