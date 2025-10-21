import 'package:flutter_naver_map/flutter_naver_map.dart';

double calculateRouteDistance(List<NLatLng> points) {
  double total = 0.0;
  for (int i = 0; i < points.length - 1; i++) {
    total += points[i].distanceTo(points[i + 1]);
  }
  return total;
}
