class Post {
  final int id;
  final String title;
  final String content;
  final int likeCount;
  final int readCount;
  final int userId;
  final DateTime createdAt;
  final List<String> images;
  final String map_image_url;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.likeCount,
    required this.readCount,
    required this.userId,
    required this.createdAt,
    required this.images,
    required this.map_image_url,
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
      map_image_url: json['map_image_url'] ?? '',
    );
  }
}
