import 'dart:convert';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/report.dart';
import 'package:http/http.dart' as http;

class ReportApi {
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
}