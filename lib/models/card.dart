class CardSummary {
  final int id;
  final String title;
  final double distance;
  final String createdAt;
  final String time;
  final String mapImageUrl;
  final int reportId;

  CardSummary({
    required this.id,
    required this.title,
    required this.distance,
    required this.createdAt,
    required this.time,
    required this.mapImageUrl,
    required this.reportId,
  });

  factory CardSummary.fromJson(Map<String, dynamic> json) {
    return CardSummary(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] ?? '',
      time: json['time'] ?? '',
      mapImageUrl: json['map_image_url'] as String? ?? '',
      reportId: json['report_id'] as int? ?? 0,
    );
  }
}