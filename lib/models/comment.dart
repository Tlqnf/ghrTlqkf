class Comment {
  final String content;
  final int? parentId;
  final int postId;
  final List<String> mentions;

  Comment({
    required this.content,
    this.parentId,
    required this.postId,
    this.mentions = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      content: json['content'] as String,
      parentId: json['parent_id'] as int?,
      postId: json['post_id'] as int,
      mentions: (json['mentions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'parent_id': parentId,
      'post_id': postId,
      'mentions': mentions,
    };
  }
}
