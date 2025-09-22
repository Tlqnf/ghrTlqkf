import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static final String baseUrl = dotenv.get('SERVER_ADDRESS');
  static final String socketUrl = baseUrl.replaceFirst('http', 'ws');
}