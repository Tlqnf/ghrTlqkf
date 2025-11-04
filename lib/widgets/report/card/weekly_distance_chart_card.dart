import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeeklyDistanceChart extends StatelessWidget {
  const WeeklyDistanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    const spots = [
      FlSpot(0, 40),
      FlSpot(1, 38),
      FlSpot(2, 30),
      FlSpot(3, 45),
      FlSpot(4, 50),
      FlSpot(5, 47),
      FlSpot(6, 43),
    ];

    final yValues = spots.map((spot) => spot.y).toList();
    final minY = (yValues.reduce((a, b) => a < b ? a : b) -10).clamp(0, double.infinity).toDouble();
    final maxY = (yValues.reduce((a, b) => a > b ? a : b) +10).toDouble();

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
                        return Text('${value.toInt()}km', style: style, textAlign: TextAlign.left);
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
