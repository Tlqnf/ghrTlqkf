import 'package:flutter/material.dart';
import 'package:pedal/api/report_api.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/report/card/today_message_card.dart';
import 'package:pedal/widgets/report/card/weekly_distance_chart_card.dart';
import 'package:pedal/widgets/report/card/weekly_speed_stat.dart';
import 'package:pedal/widgets/report/card/weekly_time_stat.dart';
import 'package:provider/provider.dart';

import 'package:pedal/models/calendar_summary.dart';
import 'package:pedal/models/daily_distance.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<DailySummary>? _dailySummaryFuture;
  Future<WeeklySummary>? _weeklySummaryFuture;
  Future<List<DailyDistance>>? _dailyDistancesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dailySummaryFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;

      _dailySummaryFuture = ReportApi.fetchDailySummary(token!, DateTime.now());
      _weeklySummaryFuture = ReportApi.getWeeklySummary(token, DateTime.now());
      _dailyDistancesFuture = ReportApi.fetchDailyDistances(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Add this line
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: FutureBuilder<List<Object>>(
          future: Future.wait([_dailySummaryFuture!, _weeklySummaryFuture!, _dailyDistancesFuture!]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data'));
            } else {
              final dailySummary = snapshot.data![0] as DailySummary;
              final weeklySummary = snapshot.data![1] as WeeklySummary;
              final dailyDistances = snapshot.data![2] as List<DailyDistance>;

              return Column(
                children: [
                  TodayMessageCard(calories: dailySummary.totalKal),
                  const SizedBox(height: 16),
                  WeeklyDistanceChart(distances: dailyDistances),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: WeeklyTimeStat(
                          weeklyTime: Duration(
                            hours: int.parse(weeklySummary.totalActivityTimeFormatted.split(':')[0]),
                            minutes: int.parse(weeklySummary.totalActivityTimeFormatted.split(':')[1]),
                            seconds: int.parse(weeklySummary.totalActivityTimeFormatted.split(':')[2]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: WeeklySpeedStat(topSpeed: weeklySummary.maxSpeed),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}