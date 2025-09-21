class CardSummary {

  final int id;
  final String title;
  final double distance;
  final String created_at;
  final int time_hour;
  final int time_minute;
  final String map_image_url;

  CardSummary({
    required this.id,
    required this.title,
    required this.distance,
    required this.created_at,
    required this.time_hour,
    required this.time_minute,
    required this.map_image_url
  });

  factory CardSummary.fromJson(Map<String, dynamic> json) {
    return CardSummary(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      created_at: json['created_at'] ?? '',
      time_hour: json['time_hour'] as int? ?? 0,
      time_minute: json['time_minute'] as int? ?? 0,
      map_image_url: json['image_url'] as String? ?? '',
    );
  }

}