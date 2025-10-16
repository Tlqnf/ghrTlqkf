class Notice {
  final int id;
  final String title;
  final String content;
  final String createdAt;
  final String? updatedAt;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
        id: json["id"],
        title: json["title"],
        content: json["content"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"] ?? "",
    );
  }
}