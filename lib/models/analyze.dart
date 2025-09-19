class Analyze {
  final int routes_taken_count;
  final int total_activity_time_hours;
  final int total_activity_time_remaining_minutes;
  final double total_activity_distance_km;

  Analyze({
    required this.routes_taken_count,
    required this.total_activity_time_hours,
    required this.total_activity_time_remaining_minutes,
    required this.total_activity_distance_km
  });

  factory Analyze.fromJson(Map<String, dynamic> json) {
    return Analyze(
        routes_taken_count: json['routes_taken_count'] ?? 0,
        total_activity_time_hours: json['total_activity_time_hours'] ?? 0,
        total_activity_time_remaining_minutes: json['total_activity_time_remaining_minutes'] ?? 0,
        total_activity_distance_km: (json['total_activity_distance_km'])?.toDouble() ?? 0.0
    );
  }

}