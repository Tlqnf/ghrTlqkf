import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:pedal/api/firebase_message_api.dart';
import 'package:pedal/api/oauth_login_auth.dart';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/webview_screen.dart';
import 'package:pedal/services/fcm_service.dart';
import 'package:pedal/services/google_sign_in_service.dart';
import 'package:pedal/widgets/bar/logo_app_bar.dart';
import 'package:pedal/widgets/login/button/social_login_button.dart';
import 'package:pedal/widgets/login/modal/terms_of_service_modal.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart';
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
    await _updateFcmToken(token); // FCM 토큰 업데이트
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
          await _extraAlertDialog();
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
        await _extraAlertDialog();
        final url = '${ApiConfig.baseUrl}/oauth/naver/login';
        if (!mounted) return;
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
          await _extraAlertDialog();
          final kakaoToken = await UserApi.instance.loginWithKakaoTalk();
          final accessToken = await OauthLoginApi.sendTokenKakao(kakaoToken.accessToken);
          if (accessToken != null) {
            await _handleLogin(accessToken);
          }
        } catch (error) {
          debugPrint('Kakao login error: $error');
          if (!mounted) return;
          showCustomSnackBar(context, '카카오톡 앱이 설치되어 있지 않아, 로그인이 취소됩니다.');
        }
      },
    );
  }

  Future<void> _extraAlertDialog() async {
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '위치정보 수집 안내',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '이 앱은 서비스 제공을 위해 사용자가 앱을 닫은 상태(백그라운드)에서도 위치 정보를 수집합니다.\n\n'
              '수집된 데이터는 주행 기록 저장, 맞춤형 알림 제공, 통계 분석에 활용되며, 언제든 설정에서 해제할 수 있습니다.\n\n'
              '이에 동의하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('동의하지 않음'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('동의함'),
          ),
        ],
      ),
    );

    if (agreed == true) {
      await Geolocator.requestPermission();
    } else {
      if (mounted) {
        showCustomSnackBar(context, '위치정보 수집이 거부되어 일부 기능이 제한됩니다.');
      }
    }

    if (mounted) {
      await Provider.of<AuthProvider>(context, listen: false)
          .checkBackgroundPermission();
    }
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