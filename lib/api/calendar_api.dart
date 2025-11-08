import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';

import '../models/calendar_summary.dart';

class CalendarApi {


  // get - calender/stamp-report/{YYYY-MM}
  // 해당 달의 스탬프 총 통계 반환
  static Future<MonthlyStampReport> fetchMonthlyStampReport(String token, int year, int month) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/calender/stamp-report/$year-${month.toString().padLeft(2, '0')}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return MonthlyStampReport.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load monthly stamp report: ${response.statusCode}');
    }
  }

  // get - calender/month-stamp
  // 각 달마다 스탬프 목록을 가져옴
  static Future<List<RideStamp>> fetchMonthStampList(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/calender/month-stamp/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((e) => RideStamp.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format (not a List)');
      }
    } else {
      throw Exception('Failed to load monthly stamp list: ${response.statusCode}');
    }
  }
  // get - calender/today-stamp
  // 오늘 스탬프 레벨을 불러옴
  static Future<RideStamp> fetchTodayStamp(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/calender/today-stamp'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return RideStamp.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load today\'s stamp: ${response.statusCode}');
    }
  }

}