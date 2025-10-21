class ReportCreate {
  final int routeId;
  final int? healthTime;
  final int? halfTime;
  final double? distance;
  final int? kcal;
  final double? averageSpeed;
  final double? highestSpeed;
  final double? averageFace;
  final double? highestFace;
  final int? cumulativeHigh;
  final int? highestHigh;
  final int? lowestHigh;
  final double? increaseSlope;
  final double? decreaseSlope;

  ReportCreate({
    required this.routeId,
    int? healthTime,
    int? halfTime,
    double? distance,
    int? kcal,
    double? averageSpeed,
    double? highestSpeed,
    double? averageFace,
    double? highestFace,
    int? cumulativeHigh,
    int? highestHigh,
    int? lowestHigh,
    double? increaseSlope,
    double? decreaseSlope,
  })  : healthTime = healthTime ?? 0,
        halfTime = halfTime ?? 0,
        distance = distance ?? 0.0,
        kcal = kcal ?? 0,
        averageSpeed = averageSpeed ?? 0.0,
        highestSpeed = highestSpeed ?? 0.0,
        averageFace = averageFace ?? 0.0,
        highestFace = highestFace ?? 0.0,
        cumulativeHigh = cumulativeHigh ?? 0,
        highestHigh = highestHigh ?? 0,
        lowestHigh = lowestHigh ?? 0,
        increaseSlope = increaseSlope ?? 0.0,
        decreaseSlope = decreaseSlope ?? 0.0;


  factory ReportCreate.fromJson(Map<String, dynamic> json) {
    return ReportCreate(
      routeId: json['route_id'] as int,
      healthTime: (json['health_time'] as num?)?.toInt(),
      halfTime: (json['half_time'] as num?)?.toInt(),
      distance: (json['distance'] as num?)?.toDouble(),
      kcal: (json['kcal'] as num?)?.toInt(),
      averageSpeed: (json['average_speed'] as num?)?.toDouble(),
      highestSpeed: (json['highest_speed'] as num?)?.toDouble(),
      averageFace: (json['average_face'] as num?)?.toDouble(),
      highestFace: (json['highest_face'] as num?)?.toDouble(),
      cumulativeHigh: (json['cumulative_high'] as num?)?.toInt(),
      highestHigh: (json['highest_high'] as num?)?.toInt(),
      lowestHigh: (json['lowest_high'] as num?)?.toInt(),
      increaseSlope: (json['increase_slope'] as num?)?.toDouble(),
      decreaseSlope: (json['decrease_slope'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'health_time': healthTime,
      'half_time': halfTime,
      'distance': distance,
      'kcal': kcal,
      'average_speed': averageSpeed,
      'highest_speed': highestSpeed,
      'average_face': averageFace,
      'highest_face': highestFace,
      'cumulative_high': cumulativeHigh,
      'highest_high': highestHigh,
      'lowest_high': lowestHigh,
      'increase_slope': increaseSlope,
      'decrease_slope': decreaseSlope,
    };
  }
}

class Report {
  final int id;
  final num healthTime;
  final num halfTime;
  final num distance;
  final num kcal;
  final num averageSpeed;
  final num highestSpeed;
  final num averageFace;
  final num highestFace;
  final num cumulativeHigh;
  final num highestHigh;
  final num lowestHigh;
  final num increaseSlope;
  final num decreaseSlope;
  final int userId;
  final String createdAt;

  Report({
    required this.id,
    required this.healthTime,
    required this.halfTime,
    required this.distance,
    required this.kcal,
    required this.averageSpeed,
    required this.highestSpeed,
    required this.averageFace,
    required this.highestFace,
    required this.cumulativeHigh,
    required this.highestHigh,
    required this.lowestHigh,
    required this.increaseSlope,
    required this.decreaseSlope,
    required this.userId,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int,
      healthTime: json['health_time'] as num,
      halfTime: json['half_time'] as num,
      distance: json['distance'] as num,
      kcal: json['kcal'] as num,
      averageSpeed: json['average_speed'] as num,
      highestSpeed: json['highest_speed'] as num,
      averageFace: json['average_face'] as num,
      highestFace: json['highest_face'] as num,
      cumulativeHigh: json['cumulative_high'] as num,
      highestHigh: json['highest_high'] as num,
      lowestHigh: json['lowest_high'] as num,
      increaseSlope: json['increase_slope'] as num,
      decreaseSlope: json['decrease_slope'] as num,
      userId: json['user_id'] as int,
      createdAt: json['created_at'] as String,
    );
  }
}