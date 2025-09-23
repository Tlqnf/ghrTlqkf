import 'dart:convert';

class Post {
  final int id;
  final String title;
  final String content;
  final int likeCount;
  final int readCount;
  final int commentCount;
  final int userId;
  final int reportId;
  final DateTime createdAt;
  final List<String> images;
  final List<String> hashTag;
  final bool public;
  final String mapImageUrl;
  final double speed;
  final double distance;
  final String time;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.likeCount,
    required this.readCount,
    required this.commentCount,
    required this.userId,
    required this.reportId,
    required this.createdAt,
    required this.images,
    required this.hashTag,
    required this.public,
    required this.mapImageUrl,
    required this.speed,
    required this.distance,
    required this.time,
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
      commentCount: json['comment_count'] ?? 0,
      userId: json['user_id'] ?? 0,
      reportId: json['report_id'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toLocal() ?? DateTime.now(),
      images: imgs,
      hashTag: List<String>.from(json['hash_tag'] ?? []),
      public: json['public'] ?? false,
      mapImageUrl: json['map_image_url'] ?? '',
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      time: json['time'] ?? '',
    );
  }
}

class CreatePost {
  final String title;
  final String content;
  final int? reportId;
  final List<String> hashTag;
  final bool public;

  CreatePost({
    required this.title,
    required this.content,
    this.reportId,
    required this.hashTag,
    required this.public,
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
