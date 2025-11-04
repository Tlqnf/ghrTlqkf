import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pedal/widgets/report/card/stat_card.dart';

class HalfCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    double padding = 10;
    final double diameter = size.width - 2 * padding;
    final double radius = diameter / 2;

    final rect = Rect.fromLTWH(padding, size.height - radius, diameter, diameter);
    const startAngle = 3.14; // 180 degrees (start from left)
    const sweepAngle = 3.14; // 180 degrees (draw a half circle)

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WeeklySpeedStat extends StatelessWidget {
  const WeeklySpeedStat({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 170,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 최고 속력',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Center(
            child: CustomPaint(
              size: const Size(120, 60), // 반원 크기
              painter: HalfCirclePainter(),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    '32 km/h',
                    style: TextStyle(
                       color: Colors.black,
                       fontWeight: FontWeight.bold,
                       fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}