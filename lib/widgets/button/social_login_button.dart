import 'package:flutter/material.dart';
import 'package:pedal/screens/webview_screen.dart';

class SocialLoginButton extends StatelessWidget {
  final String source;
  final String text;
  final String type;
  final Function(String) onLogin;

  const SocialLoginButton({
    super.key,
    required this.source,
    required this.text,
    required this.type,
    required this.onLogin,
  });

  String _getUrlForType(String type) {
    switch (type) {
      case 'google':
        return 'http://172.30.1.14:8080/oauth/google/login';
      case 'naver':
        return 'http://172.30.1.14:8080/oauth/naver/login';
      case 'kakao':
        return 'http://172.30.1.14:8080/oauth/kakao/login';
      default:
        throw Exception('Unknown login type: $type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final url = _getUrlForType(type);
        final token = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(url: url),
          ),
        );
        if (token != null && token is String) {
          onLogin(token);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(source, height: 30),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}