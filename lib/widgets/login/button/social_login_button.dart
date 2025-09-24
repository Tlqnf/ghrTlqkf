import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:pedal/api/oauth_login_auth.dart';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/services/google_sign_in_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        switch (type) {
          case 'google':
            await _signInWithGoogle();
            break;
          case 'naver':
            final url = '${ApiConfig.baseUrl}/oauth/naver/login';
            final token = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebViewScreen(url: url),
              ),
            );
            if (token != null && token is String) {
              onLogin(token);
            }
            break;
          case 'kakao':
            await _signInWithKakao();
            break;
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(source, height: 30),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Google 로그인
  Future<void> _signInWithGoogle() async {
    try {
      final account = await GoogleSignInService().signIn();
      if (account == null) return; // 사용자가 취소한 경우
      final auth = account.authentication;
      final idToken = auth.idToken;

      if (idToken != null) {
        final token = await OauthLoginApi.sendTokenGoogle(idToken);
        onLogin(token!);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Kakao 로그인
  Future<void> _signInWithKakao() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
      final accessToken = await OauthLoginApi.sendTokenKakao(token.accessToken);
      if (accessToken != null) {
        onLogin(accessToken);
      }
    } catch (error) {
      rethrow;
    }
  }
}
