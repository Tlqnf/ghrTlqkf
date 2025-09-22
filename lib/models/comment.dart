class CreateComment {
  final String content;
  final int? parentId;
  final int postId;
  final List<String> mentions;

  CreateComment({
    required this.content,
    this.parentId,
    required this.postId,
    this.mentions = const [],
  });

  factory CreateComment.fromJson(Map<String, dynamic> json) {
    return CreateComment(
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

class Comment {
  final int commentId;
  final String content;
  final int userId;
  final int postId;
  final int likeCount;
  final int commentCount;

  Comment({
    required this.commentId,
    required this.content,
    required this.userId,
    required this.postId,
    required this.likeCount,
    required this.commentCount,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json["comment_id"] as int,
      content: json["content"] as String,
      userId: json["user_id"] as int,
      postId: json["post_id"] as int,
      likeCount: json["like_count"] as int,
      commentCount: json["comment_count"] as int,
    );
  }
}

class Reply {
  final int id;
  final int userId;
  final String content;
  final int likeCount;
  final int postId;
  final int parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String username;
  final String profilePic;

  Reply({
    required this.id,
    required this.userId,
    required this.content,
    required this.likeCount,
    required this.postId,
    required this.parentId,
    required this.createdAt,
    required this.updatedAt,
    required this.username,
    required this.profilePic,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      content: json['content'] as String,
      likeCount: json['like_count'] as int,
      postId: json['post_id'] as int,
      parentId: json['parent_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: json['username'] as String,
      profilePic: json['profile_pic'] as String,
    );
  }
}