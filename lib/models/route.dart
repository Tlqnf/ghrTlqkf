class Route {
  final String name;
  final int id;
  final String createdAt;
  final List<dynamic> pointsJson;
  final Map<String, dynamic> startPoint;
  final Map<String, dynamic> endPoint;
  final List<dynamic> tags;

  Route({
    required this.name,
    required this.id,
    required this.createdAt,
    required this.pointsJson,
    required this.startPoint,
    required this.endPoint,
    required this.tags,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      name: json['name'],
      id: json['id'],
      createdAt: json['created_at'],
      pointsJson: json['points_json'],
      startPoint: json['start_point'],
      endPoint: json['end_point'],
      tags: json['tags'],
    );
  }
}

class GuideRoute {
  final double startLat;
  final double startLon;
  final double finishLat;
  final double finishLon;

  GuideRoute({
    required this.startLat,
    required this.startLon,
    required this.finishLat,
    required this.finishLon,
  });

  Map<String, dynamic> toJson() => {
    'start_lat': startLat,
    'start_lon': startLon,
    'finish_lat': finishLat,
    'finish_lon': finishLon,
  };
}