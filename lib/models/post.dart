class Post {
  final int id;
  final String title;
  final String content;
  final int likeCount;
  final int readCount;
  final int userId;
  final DateTime createdAt;
  final List<dynamic> images;
  final Map<String, dynamic>? route;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.likeCount,
    required this.readCount,
    required this.userId,
    required this.createdAt,
    required this.images,
    this.route,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      likeCount: json['like_count'] ?? 0,
      readCount: json['read_count'] ?? 0,
      userId: json['user_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      images: json['images'] as List<dynamic>? ?? [],
      route: json['route'] as Map<String, dynamic>?,
    );
  }
}