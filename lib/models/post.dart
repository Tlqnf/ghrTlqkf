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
  final int routeId;
  final DateTime createdAt;
  final List<Map<String, dynamic>> images; // <-- 그대로 Map
  final List<String> hashTag;
  final bool public;
  final String mapImageUrl;
  final String routeName;
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
    required this.routeId,
    required this.createdAt,
    required this.images,
    required this.hashTag,
    required this.public,
    required this.mapImageUrl,
    required this.routeName,
    required this.speed,
    required this.distance,
    required this.time,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final imgs = (json['images'] as List?)
        ?.map((e) => {
      "id": e['id'],
      "url": e['url'],
    })
        .toList() ??
        <Map<String, dynamic>>[];

    return Post(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      likeCount: json['like_count'] ?? 0,
      readCount: json['read_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      userId: json['user_id'] ?? 0,
      reportId: json['report_id'] ?? 0,
      routeId: json["route_id"] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toLocal() ?? DateTime.now(),
      images: imgs, // List<Map<String, dynamic>>
      hashTag: List<String>.from(json['hash_tag'] ?? []),
      public: json['public'] ?? false,
      mapImageUrl: json['map_image_url'] ?? '',
      routeName: json['route_name'] ?? '',
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
  final int? routeId;
  final List<String> hashTag;
  final bool public;

  CreatePost({
    required this.title,
    required this.content,
    this.reportId,
    this.routeId,
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
    if (routeId != null) data['route_id'] = routeId;
    return data;
  }

  String toJsonString() => json.encode(toJson());
}

class UpdatePost {
  final String title;
  final String content;
  final int? reportId;
  final List<String> hashTag;
  final bool public;
  final List<int>? imagesToKeepIds;

  UpdatePost({
    required this.title,
    required this.content,
    this.reportId,
    required this.hashTag,
    required this.public,
    this.imagesToKeepIds,
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
    if (imagesToKeepIds != null) data['images_to_keep_ids'] = imagesToKeepIds;

    return data;
  }

  String toJsonString() => json.encode(toJson());
}