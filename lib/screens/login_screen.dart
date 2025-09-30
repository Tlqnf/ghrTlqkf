import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:pedal/api/firebase_message_api.dart';
import 'package:pedal/api/oauth_login_auth.dart';
import 'package:pedal/api/user_api.dart' as user;
import 'package:pedal/config/api_config.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/webview_screen.dart';
import 'package:pedal/services/fcm_service.dart';
import 'package:pedal/services/google_sign_in_service.dart';
import 'package:pedal/widgets/bar/logo_app_bar.dart';
import 'package:pedal/widgets/login/button/social_login_button.dart';
import 'package:pedal/widgets/login/modal/terms_of_service_modal.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _handleLogin(String token) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.login(token);

    try {
      // 1. 사용자 프로필 가져오기
      await user.UserApi.fetchUserProfile(token);

      // 2. FCM 토큰 업데이트
      await _updateFcmToken(token);
    } catch (e) {
      debugPrint('로그인 프로세스 오류: $e');
      if (!mounted) return;
      authProvider.logout();
    }
  }

  Future<void> _updateFcmToken(String token) async {
    try {
      final fcmService = FCMService();
      final fcmToken = await fcmService.getToken();
      if (fcmToken != null) {
        await FcmApiService.updateUserFcmToken(token, fcmToken);
      }
    } catch (e) {
      debugPrint('FCM 토큰 업데이트 오류: $e');
    }
  }

  void _loginWithGoogle() {
    showTermsOfServiceModal(
      context,
      onAgreed: () async {
        try {
          final account = await GoogleSignInService().signIn();
          if (account == null) return; // User cancelled
          final auth = account.authentication;
          final idToken = auth.idToken;

          if (idToken != null) {
            final token = await OauthLoginApi.sendTokenGoogle(idToken);
            if (token != null) {
              await _handleLogin(token);
            }
          }
        } catch (e) {
          debugPrint('Google login error: $e');
        }
      },
    );
  }

  void _loginWithNaver() {
    showTermsOfServiceModal(
      context,
      onAgreed: () async {
        final url = '${ApiConfig.baseUrl}/oauth/naver/login';
        final token = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewScreen(url: url),
          ),
        );
        if (token != null && token is String) {
          await _handleLogin(token);
        }
      },
    );
  }

  void _loginWithKakao() {
    showTermsOfServiceModal(
      context,
      onAgreed: () async {
        try {
          final kakaoToken = await UserApi.instance.loginWithKakaoTalk();
          final accessToken = await OauthLoginApi.sendTokenKakao(kakaoToken.accessToken);
          if (accessToken != null) {
            await _handleLogin(accessToken);
          }
        } catch (error) {
          debugPrint('Kakao login error: $error');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '로그인',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            SocialLoginButton(
              source: "assets/image/google.png",
              text: 'Google 계정으로 로그인',
              onPressed: _loginWithGoogle,
            ),
            const SizedBox(height: 16),
            SocialLoginButton(
              source: "assets/image/naver.png",
              text: 'Naver 계정으로 로그인',
              onPressed: _loginWithNaver,
            ),
            const SizedBox(height: 16),
            SocialLoginButton(
              source: "assets/image/kakao.png",
              text: 'Kakao 계정으로 로그인',
              onPressed: _loginWithKakao,
            ),
          ],
        ),
      ),
    );
  }
}