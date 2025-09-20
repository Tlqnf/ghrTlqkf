import 'dart:convert';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/models/report.dart';
import 'package:http/http.dart' as http;

class ReportApiService {
  // report의 아이디만 제공
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
}