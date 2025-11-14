import 'dart:math';
import 'package:flutter/material.dart';

class HalfCirclePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  HalfCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.pinkAccent
          .withValues(alpha: 0.2) // 배경 색상
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = Colors
          .pinkAccent // 진행 상태 색상
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    double padding = 10;
    final double diameter = size.width - 2 * padding;
    final double radius = diameter / 2;

    final rect = Rect.fromLTWH(
      padding,
      size.height - radius,
      diameter,
      diameter,
    );
    const double startAngle = pi; // 180도 (왼쪽에서 시작)
    const double fullSweepAngle = pi; // 180도 (반원)

    // 배경 반원 그리기
    canvas.drawArc(rect, startAngle, fullSweepAngle, false, backgroundPaint);

    // 진행 상태 반원 그리기
    final double progressSweepAngle = fullSweepAngle * progress;
    canvas.drawArc(rect, startAngle, progressSweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant HalfCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class WeeklySpeedStat extends StatelessWidget {
  final double topSpeed;

  const WeeklySpeedStat({super.key, required this.topSpeed});

  @override
  Widget build(BuildContext context) {
    const double goal = 30.0; // 목표 속도
    final double progress = topSpeed / goal;

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
              painter: HalfCirclePainter(progress: progress.clamp(0.0, 1.0)),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    '${topSpeed.toStringAsFixed(1)} km/h',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
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
