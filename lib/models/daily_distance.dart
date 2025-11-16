class DailyDistance {
  final DateTime date;
  final int distance;

  DailyDistance({required this.date, required this.distance});

  factory DailyDistance.fromJson(Map<String, dynamic> json) {
    return DailyDistance(
      date: DateTime.parse(
        json['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      distance: (json['distance'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'distance': distance};
  }
}
