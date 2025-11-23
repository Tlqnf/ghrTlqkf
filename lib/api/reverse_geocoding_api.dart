import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NaverGeocodingService {
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=$lng,$lat&output=json&orders=addr,roadaddr'
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'X-NCP-APIGW-API-KEY-ID': dotenv.env["NAVER_CLIENT_ID"] ?? "",
          'X-NCP-APIGW-API-KEY': dotenv.env["NAVER_CLIENT_SECRET_KEY"] ?? "",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 도로명주소 우선, 없으면 지번주소
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final region = result['region'];
          final land = result['land'];

          // 도로명주소
          if (land != null && land['name'] != null) {
            return '${region['area1']['name']} ${region['area2']['name']} '
                   '${land['name']} ${land['number1']}';
          }

          // 지번주소
          return '${region['area1']['name']} ${region['area2']['name']} '
                 '${region['area3']['name']} ${land['number1']}';
        }
      }
    } catch (e) {
      debugPrint('Reverse Geocoding Error: $e');
    }

    return null;
  }
}