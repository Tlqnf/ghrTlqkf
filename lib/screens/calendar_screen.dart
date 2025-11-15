import 'package:flutter/material.dart';
import 'package:pedal/api/calendar_api.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/calendar/card/medal_summary_card.dart';
import 'package:provider/provider.dart';

import 'package:pedal/models/calendar_summary.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<MonthlyStampReport>? _monthlyStampReportFuture;
  Future<List<RideStamp>>? _rideStampsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_monthlyStampReportFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final now = DateTime.now();
      _monthlyStampReportFuture = CalendarApi.fetchMonthlyStampReport(
        token!,
        now.year,
        now.month,
      );
      _rideStampsFuture = CalendarApi.fetchMonthStampList(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Scaffold 제거하고 Container로 변경
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 0,      // 상단 여백 제거
          bottom: 16,  // 하단 최소 패딩
        ),
        child: FutureBuilder<List<Object>>(
          future: Future.wait([_monthlyStampReportFuture!, _rideStampsFuture!]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            } else if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No data')),
              );
            }

            final monthlyStampReport = snapshot.data![0] as MonthlyStampReport;
            final rideStamps = snapshot.data![1] as List<RideStamp>;

            return Column(
              mainAxisSize: MainAxisSize.min, // 컨텐츠 크기에 맞춤
              children: [
                MedalAndCalendarSection(
                  getMedal: monthlyStampReport.getStampsNum,
                  getMonthDay: monthlyStampReport.daysOfMonth,
                  avgMedalIndex: monthlyStampReport.averageOfStampLev,
                  growRate: monthlyStampReport.levRaiseRate,
                  rideData: rideStamps,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}