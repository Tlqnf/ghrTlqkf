import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String source;
  final String text;
  // 경로 지정하는데 활용하시오. (google, naver, kakao 중 1개)
  final String type;

  const SocialLoginButton({
    super.key,
    required this.source,
    required this.text,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {_},
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
          SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
