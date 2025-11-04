import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/report/card/today_message_card.dart';
import '../widgets/report/card/weekly_distance_chart_card.dart';
import '../widgets/report/card/weekly_speed_stat.dart';
import '../widgets/report/card/weekly_time_stat.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '일지',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TodayMessageCard(calories: 450,),
            SizedBox(height: 16),
            WeeklyDistanceChart(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: WeeklyTimeStat()),
                SizedBox(width: 16),
                Expanded(child: WeeklySpeedStat()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}