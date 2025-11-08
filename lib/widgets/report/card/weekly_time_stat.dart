import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pedal/widgets/report/card/stat_card.dart';

class WeeklyTimeStat extends StatelessWidget {
  final Duration weeklyTime;

  const WeeklyTimeStat({super.key, required this.weeklyTime});

  @override
  Widget build(BuildContext context) {
    const Duration goal = Duration(hours: 10);
    final double progress = weeklyTime.inSeconds / goal.inSeconds;

    String formatDuration(Duration d) {
      final hours = d.inHours.toString().padLeft(2, '0');
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }

    return StatCard(
      title: '이번 주 시간',
      value: formatDuration(weeklyTime),
      color: Colors.blueAccent,
      textColor: Colors.black,
      progress: progress.clamp(0.0, 1.0),
    );
  }
}
