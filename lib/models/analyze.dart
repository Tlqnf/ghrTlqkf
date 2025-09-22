class Analyze {
  final int routesTakenCount;
  final int totalActivityTimeHours;
  final int totalActivityTimeRemainingMinutes;
  final double totalActivityDistanceKm;

  Analyze({
    required this.routesTakenCount,
    required this.totalActivityTimeHours,
    required this.totalActivityTimeRemainingMinutes,
    required this.totalActivityDistanceKm,
  });

  factory Analyze.fromJson(Map<String, dynamic> json) {
    return Analyze(
        routesTakenCount: json['routes_taken_count'] ?? 0,
        totalActivityTimeHours: json['total_activity_time_hours'] ?? 0,
        totalActivityTimeRemainingMinutes: json['total_activity_time_remaining_minutes'] ?? 0,
        totalActivityDistanceKm: (json['total_activity_distance_km'])?.toDouble() ?? 0.0
    );
  }

}