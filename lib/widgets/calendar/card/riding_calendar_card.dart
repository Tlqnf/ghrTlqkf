import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:pedal/models/calendar_summary.dart';

// 서버 데이터 모델

class RidingCalendarCard extends StatefulWidget {
  final List<RideStamp> rideData;

  const RidingCalendarCard({super.key, required this.rideData});

  @override
  State<RidingCalendarCard> createState() => _RidingCalendarCardState();
}

class _RidingCalendarCardState extends State<RidingCalendarCard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Map<DateTime, int> _stampData;

  @override
  void initState() {
    super.initState();
    _stampData = _processRideData(widget.rideData);
  }

  Map<DateTime, int> _processRideData(List<RideStamp> rideData) {
    final Map<DateTime, int> data = {};
    for (var ride in rideData) {
      // Normalize the date to ignore time
      final date = DateTime.utc(ride.date.year, ride.date.month, ride.date.day);
      data[date] = ride.stampLev;
    }
    return data;
  }

  // 스탬프 레벨별 색상 매핑
  Color _getStampColor(int stampLev) {
    switch (stampLev) {
      case 5: // 마스터
        return const Color(0xFF9C27B0);
      case 4: // 다이아몬드
        return const Color(0xFF03A9F4);
      case 3: // 금메달
        return const Color(0xFFFFD54F);
      case 2: // 은메달
        return const Color(0xFFB0BEC5);
      case 1: // 동메달
        return const Color(0xFF8D6E63);
      default:
        return Colors.transparent;
    }
  }

  // 해당 날짜의 스탬프 위젯
  Widget? _stampMarker(DateTime day) {
    final stampLev = _stampData[day];
    if (stampLev == null) return null;

    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _getStampColor(stampLev),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Text(
                '라이딩 캘린더',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(width: 6),
              Icon(Icons.info_outline, size: 16, color: Colors.black45),
            ],
          ),
          const SizedBox(height: 12),
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left),
              rightChevronIcon: Icon(Icons.chevron_right),
            ),
            calendarStyle: const CalendarStyle(isTodayHighlighted: false),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _stampMarker(day),
              outsideBuilder: (context, day, focusedDay) => _stampMarker(day),
              todayBuilder: (context, day, focusedDay) => _stampMarker(day),
              selectedBuilder: (context, day, focusedDay) => _stampMarker(day),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
        ],
      ),
    );
  }
}
