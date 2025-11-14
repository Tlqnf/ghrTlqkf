class DailySummary {
  final int routesTakenCount;
  final String totalActivityTimeFormatted;
  final double totalActivityDistanceKm;
  final double maxSpeed;
  final int totalKal;

  DailySummary({
    required this.routesTakenCount,
    required this.totalActivityTimeFormatted,
    required this.totalActivityDistanceKm,
    required this.maxSpeed,
    required this.totalKal,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      routesTakenCount: (json['routes_taken_count'] as num?)?.toInt() ?? 0,
      totalActivityTimeFormatted:
          json['total_activity_time_formatted'] as String? ?? '00:00:00',
      totalActivityDistanceKm:
          (json['total_activity_distance_km'] as num?)?.toDouble() ?? 0.0,
      maxSpeed: (json['max_speed'] as num?)?.toDouble() ?? 0.0,
      totalKal: (json['total_kal'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routes_taken_count': routesTakenCount,
      'total_activity_time_formatted': totalActivityTimeFormatted,
      'total_activity_distance_km': totalActivityDistanceKm,
      'max_speed': maxSpeed,
      'total_kal': totalKal,
    };
  }
}

class MonthlyComparison {
  final int changeType;
  final double distanceChange;

  MonthlyComparison({required this.changeType, required this.distanceChange});

  factory MonthlyComparison.fromJson(Map<String, dynamic> json) {
    return MonthlyComparison(
      changeType: (json['change_type'] as num?)?.toInt() ?? 0,
      distanceChange: (json['distance_change'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'change_type': changeType, 'distance_change': distanceChange};
  }
}

class MonthlyStampReport {
  final int stampOfYear;
  final int stampOfMonth;
  final int daysOfMonth;
  final int averageOfStampLev;
  final int getStampsNum;
  final int levRaiseRate;

  MonthlyStampReport({
    required this.stampOfYear,
    required this.stampOfMonth,
    required this.daysOfMonth,
    required this.averageOfStampLev,
    required this.getStampsNum,
    required this.levRaiseRate,
  });

  factory MonthlyStampReport.fromJson(Map<String, dynamic> json) {
    return MonthlyStampReport(
      stampOfYear: (json['stamp_of_year'] as num?)?.toInt() ?? 0,
      stampOfMonth: (json['stamp_of_month'] as num?)?.toInt() ?? 0,
      daysOfMonth: (json['days_of_month'] as num?)?.toInt() ?? 0,
      averageOfStampLev: (json['average_of_stamp_lev'] as num?)?.toInt() ?? 0,
      getStampsNum: (json['get_stamps_num'] as num?)?.toInt() ?? 0,
      levRaiseRate: (json['lev_raise_rate'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stamp_of_year': stampOfYear,
      'stamp_of_month': stampOfMonth,
      'days_of_month': daysOfMonth,
      'average_of_stamp_lev': averageOfStampLev,
      'get_stamps_num': getStampsNum,
      'lev_raise_rate': levRaiseRate,
    };
  }
}

class UserLevel {
  final String lev;
  final int exp;
  final int nextLevExp;

  UserLevel({required this.lev, required this.exp, required this.nextLevExp});

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      lev: json['lev'] as String? ?? '',
      exp: int.tryParse(json['exp'].toString()) ?? 0,
      nextLevExp: int.tryParse(json['next_lev_exp'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'lev': lev, 'exp': exp, 'next_lev_exp': nextLevExp};
  }
}

class WeeklySummary {
  final int routesTakenCount;
  final String totalActivityTimeFormatted;
  final double totalActivityDistanceKm;
  final double maxSpeed;
  final int totalKal;

  WeeklySummary({
    required this.routesTakenCount,
    required this.totalActivityTimeFormatted,
    required this.totalActivityDistanceKm,
    required this.maxSpeed,
    required this.totalKal,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      routesTakenCount: json['routes_taken_count'] as int,
      totalActivityTimeFormatted:
          json['total_activity_time_formatted'] as String,
      totalActivityDistanceKm: (json['total_activity_distance_km'] as num)
          .toDouble(),
      maxSpeed: (json['max_speed'] as num).toDouble(),
      totalKal: json['total_kal'] as int,
    );
  }
}

class RideStamp {
  final DateTime date;
  final int stampLev;

  RideStamp({required this.date, required this.stampLev});

  factory RideStamp.fromJson(Map<String, dynamic> json) {
    return RideStamp(
      date: DateTime.parse(json['date']),
      stampLev: json['stamp_lev'],
    );
  }
}
