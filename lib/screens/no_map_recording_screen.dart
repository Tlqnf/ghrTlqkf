import 'package:flutter/material.dart';

class NoMapRecordingView extends StatelessWidget {
  final double currentSpeed;
  final bool isPaused;
  final VoidCallback togglePause;
  final double distance;
  final String elapsedTime;
  final double avgSpeed;
  final double maxSpeed;

  const NoMapRecordingView({
    super.key,
    required this.currentSpeed,
    required this.isPaused,
    required this.togglePause,
    required this.distance,
    required this.elapsedTime,
    required this.avgSpeed,
    required this.maxSpeed,
  });

  Widget _buildNoMapStatRow(
      String title1, String value1, String title2, String value2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(child: _buildNoMapStat(title1, value1)),
        const SizedBox(width: 20),
        Expanded(child: _buildNoMapStat(title2, value2)),
      ],
    );
  }

  Widget _buildNoMapStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 36,
              color: Color(0xFF007AFF),
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 180), // Bottom padding for controls
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          const Text('현재 속력', style: TextStyle(fontSize: 20, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            currentSpeed.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 96,
              color: Color(0xFF007AFF),
              fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: togglePause,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isPaused ? Colors.orange : Colors.green
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              isPaused ? '라이딩 일시정지' : '라이딩 진행중',
              style: TextStyle(
                color: isPaused ? Colors.orange : Colors.green,
                fontSize: 16
              ),
            ),
          ),
          const SizedBox(height: 60),
          _buildNoMapStatRow('거리(km)', (distance / 1000).toStringAsFixed(2),
              '시간', elapsedTime),
          const SizedBox(height: 30),
          _buildNoMapStatRow('평균 속력', avgSpeed.toStringAsFixed(1), '최고 속도',
              maxSpeed.toStringAsFixed(1)),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
