class CardSummary {

  final int id;
  final String title;
  final double distance;
  final String createdAt;
  final int timeHour;
  final int timeMinute;
  final String mapImageUrl;

  CardSummary({
    required this.id,
    required this.title,
    required this.distance,
    required this.createdAt,
    required this.timeHour,
    required this.timeMinute,
    required this.mapImageUrl
  });

  factory CardSummary.fromJson(Map<String, dynamic> json) {
    return CardSummary(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] ?? '',
      timeHour: json['time_hour'] as int? ?? 0,
      timeMinute: json['time_minute'] as int? ?? 0,
      mapImageUrl: json['image_url'] as String? ?? '',
    );
  }

}