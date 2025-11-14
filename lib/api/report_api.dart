import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/report.dart';
import 'package:http/http.dart' as http;

import 'package:pedal/models/calendar_summary.dart';

import 'package:pedal/models/daily_distance.dart';

class ReportApi {
  // get - report/daily-distance
  // 주간 하루 거리 정보를 반환
  static Future<List<DailyDistance>> fetchDailyDistances(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/daily-distance'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((e) => DailyDistance.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format (not a List)');
      }
    } else {
      throw Exception('Failed to load daily distances: ${response.statusCode}');
    }
  }

  // post - report
  // 리포트 생성
  static Future<int> createReport(ReportCreate reportData, String token) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/report"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode(reportData.toJson()),
    );
    if (response.statusCode == 200) {
      return Report.fromJson(jsonDecode(response.body)).id;
    } else {
      throw Exception('Failed to create Report: ${response.body}');
    }
  }

  // get - report
  // (아마 관리자 전용?) 리포트 전체 조회
  static Future<List<Report>> getReports(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reports: ${response.statusCode}');
    }
  }

  // get - report/{reportId}
  // 리포트 상세 조회
  static Future<Report> getReportById(String token, int reportId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/$reportId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Report.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load report $reportId: ${response.statusCode}');
    }
  }

  // patch - report/{reportId}
  // 리포트 수정
  static Future<void> updateReport(String token, int reportId, ReportCreate reportData) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/report/$reportId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(reportData.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update report $reportId: ${response.statusCode}');
    }
  }

  // get - report/by-user
  // 유저 필터로 리포트 가져오기
  static Future<List<Report>> getReportsByUser(String token, String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/by-user?userId=$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reports for user $userId: ${response.statusCode}');
    }
  }

  // get - report/by-route-user (body routeId, userId?)
  // 경로&유저 필터로 리포트 가져오기
  static Future<List<Report>> getReportsByRouteAndUser(String token, int routeId, String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/by-route-user?routeId=$routeId&userId=$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reports for route $routeId and user $userId: ${response.statusCode}');
    }
  }



  // get - report/weekly-summary
  // 주간 기록 요약 가져오기
  static Future<WeeklySummary> getWeeklySummary(String token, DateTime date) async {
    final formattedDate = date.toIso8601String();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/weekly-summary?date=$formattedDate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return WeeklySummary.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      debugPrint('Failed to load weekly record: ${utf8.decode(response.bodyBytes)}');
      throw Exception('Failed to load weekly record: ${response.statusCode}');
    }
  }

  // get - report/lev
  // 유저 레벨 및 경험치 조회
  static Future<UserLevel> fetchUserLevel(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/lev'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return UserLevel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user level: ${response.statusCode}');
    }
  }

  // get - /monthly-comparison
  // 지난달 대비 상승률 반환
  static Future<MonthlyComparison> fetchMonthlyComparison(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/monthly-comparison'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return MonthlyComparison.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to load monthly comparison: ${response.statusCode}');
    }
  }

  // get - report/daily-summary
  // 오늘 하루 통계 가져오기
  static Future<DailySummary> fetchDailySummary(String token, DateTime date) async {
    final formattedDate = date.toIso8601String();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/daily-summary/?date=$formattedDate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return DailySummary.fromJson(jsonDecode(response.body));
    } else {
      debugPrint('Failed to load daily summary: ${response.body}');
      throw Exception('Failed to load daily summary: ${response.statusCode}');
    }
  }
}