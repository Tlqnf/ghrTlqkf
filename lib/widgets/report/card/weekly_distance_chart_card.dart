import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pedal/models/daily_distance.dart';

class WeeklyDistanceChart extends StatelessWidget {
  final List<DailyDistance> distances;

  const WeeklyDistanceChart({super.key, required this.distances});

  @override
  Widget build(BuildContext context) {
    final spots = distances
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.distance.toDouble()))
        .toList();

    final yValues = spots.map((spot) => spot.y).toList();
    final minY = yValues.isEmpty
        ? 0.0
        : (((yValues.reduce((a, b) => a < b ? a : b) - 10) / 10).floor() * 10)
              .clamp(0, double.infinity)
              .toDouble();
    final maxY = yValues.isEmpty
        ? 50.0
        : (((yValues.reduce((a, b) => a > b ? a : b) + 10) / 10).ceil() * 10)
              .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 거리',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: minY,
                maxY: maxY,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) {
                        const style = TextStyle(
                          color: Color(0xff68737d),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = '월';
                            break;
                          case 1:
                            text = '화';
                            break;
                          case 2:
                            text = '수';
                            break;
                          case 3:
                            text = '목';
                            break;
                          case 4:
                            text = '금';
                            break;
                          case 5:
                            text = '토';
                            break;
                          case 6:
                            text = '일';
                            break;
                          default:
                            text = '';
                            break;
                        }
                        return Text(text, style: style);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10, // Set interval to 10
                      getTitlesWidget: (value, _) {
                        const style = TextStyle(
                          color: Color(0xff67727d),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        return Text(
                          '${value.toInt()}km',
                          style: style,
                          textAlign: TextAlign.left,
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xff37434d),
                      strokeWidth: 0.5,
                      dashArray: [5, 5],
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(
                      color: Color(0xff37434d),
                      strokeWidth: 0.5,
                      dashArray: [5, 5],
                    );
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    dotData: FlDotData(show: true), // Show dots
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
