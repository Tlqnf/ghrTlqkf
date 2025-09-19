import 'package:flutter/material.dart';
import 'package:pedal/widgets/button/social_login_button.dart';
import 'package:pedal/widgets/bar/logo_bar.dart';

class LoginPage extends StatelessWidget {
  final Function(String) onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              type: 'google',
              onLogin: onLogin,
            ),
            const SizedBox(height: 16),
            SocialLoginButton(
              source: "assets/image/naver.png",
              text: 'Naver 계정으로 로그인',
              type: 'naver',
              onLogin: onLogin,
            ),
            const SizedBox(height: 16),
            SocialLoginButton(
              source: "assets/kakao.png",
              text: 'Kakao 계정으로 로그인',
              type: 'kakao',
              onLogin: onLogin,
            ),
          ],
        ),
      ),
    );
  }
}