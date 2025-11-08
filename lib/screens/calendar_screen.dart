import 'package:flutter/material.dart';
import 'package:pedal/api/calendar_api.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/calendar/card/medal_summary_card.dart';
import 'package:pedal/widgets/calendar/card/riding_calendar_card.dart';
import 'package:provider/provider.dart';

import '../models/calendar_summary.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<MonthlyStampReport>? _monthlyStampReportFuture;
  Future<List<RideStamp>>? _rideStampsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_monthlyStampReportFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token!=null? Provider.of<AuthProvider>(context, listen: false).token:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTAxNDY2fQ.xBgQTC9zWmDBlL5VyXCylbmfdR0f37nr7MBgoOgG9fQ";
      if (token != null) {
        final now = DateTime.now();
        _monthlyStampReportFuture = CalendarApi.fetchMonthlyStampReport(token, now.year, now.month);
        _rideStampsFuture = CalendarApi.fetchMonthStampList(token);
      } else {
        _monthlyStampReportFuture = Future.error('Not authenticated');
        _rideStampsFuture = Future.error('Not authenticated');
      }
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
          future: Future.wait([_monthlyStampReportFuture!, _rideStampsFuture!]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data'));
            } else {
              final monthlyStampReport = snapshot.data![0] as MonthlyStampReport;
              final rideStamps = snapshot.data![1] as List<RideStamp>;

              return MedalAndCalendarSection(
                getMedal: monthlyStampReport.getStampsNum,
                getMonthDay: monthlyStampReport.daysOfMonth,
                avgMedalIndex: monthlyStampReport.averageOfStampLev,
                growRate: monthlyStampReport.levRaiseRate,
                rideData: rideStamps,
              );
            }
          },
        ),
      ),
    );
  }
}
