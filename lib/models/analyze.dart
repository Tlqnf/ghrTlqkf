import 'dart:ffi';

class Analyze {
  final Int routes_taken_count;
  final Int total_activity_time_hours;
  final Int total_activity_time_remaining_minutes;
  final Float total_activity_distance_km;

  Analyze({
    required this.routes_taken_count,
    required this.total_activity_time_hours,
    required this.total_activity_time_remaining_minutes,
    required this.total_activity_distance_km
  });

  factory Analyze.fromJson(Map<String, dynamic> json) {
    return Analyze(routes_taken_count: json['routes_taken_count'], total_activity_time_hours: json['total_activity_time_hours'], total_activity_time_remaining_minutes: json['total_activity_time_remaining_minutes'], total_activity_distance_km: json['total_activity_distance_km']);
  }

}