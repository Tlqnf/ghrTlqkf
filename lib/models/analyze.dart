class Analyze {
  final int routesTakenCount;
  final String totalActivityTimeFormatted;
  final double totalActivityDistanceKm;

  Analyze({
    required this.routesTakenCount,
    required this.totalActivityTimeFormatted,
    required this.totalActivityDistanceKm,
  });

  factory Analyze.fromJson(Map<String, dynamic> json) {
    return Analyze(
        routesTakenCount: json['routes_taken_count'] ?? 0,
        totalActivityTimeFormatted: json['total_activity_time_formatted'] ?? 0,
        totalActivityDistanceKm: (json['total_activity_distance_km'])?.toDouble() ?? 0.0
    );
  }

}