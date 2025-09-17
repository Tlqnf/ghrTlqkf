import 'package:flutter/material.dart';

// Scaffold에게 자신의 높이가 몇 인지 알려주는 기능 포함 -> PreferredSizeWidget
class LogoBar extends StatelessWidget implements PreferredSizeWidget {
  const LogoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white, // 스크롤 시 색상 변경 방지
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
                "assets/Logo.png",
                height: 35
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'PEDAL',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      )
    );
  }

  // Appbar 표준 높이 지정
  @override
  Size get preferredSize => const Size.fromHeight((kToolbarHeight));
}