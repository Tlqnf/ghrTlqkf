import 'dart:convert';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/report.dart';
import 'package:http/http.dart' as http;

class ReportApiService {
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
      throw Exception('Failed to create Report: ${response.statusCode}');
    }
  }

  // get - report
  // (아마 관리자 전용?) 리포트 전체 조회

  // get - report/{reportId}
  // 리포트 상세 조회

  // patch - report/{reportId}
  // 리포트 수정

  // get - report/by-user
  // 유저 리포트 가져오기

  // get - report/by-route-user
  // 경로 - 유저 리포트 가져오기
}