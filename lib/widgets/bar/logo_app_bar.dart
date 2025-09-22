import 'package:flutter/material.dart';

// Scaffold에게 자신의 높이가 몇 인지 알려주는 기능 포함 -> PreferredSizeWidget
class LogoBar extends StatelessWidget implements PreferredSizeWidget {
  const LogoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.background,
      surfaceTintColor: Theme.of(context).colorScheme.background, // 스크롤 시 색상 변경 방지
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset("assets/Logo.png", height: 35),
          ),
          const SizedBox(width: 8),
          const Text(
            'PEDAL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            // Handle notification button press
            print('Notification button pressed');
          },
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('프로필 수정'),
                      onTap: () {
                        Navigator.pop(context); // Close the modal
                        print('프로필 수정 selected');
                        // Navigate to profile edit screen
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('로그아웃'),
                      onTap: () {
                        Navigator.pop(context); // Close the modal
                        print('로그아웃 selected');
                        // Handle logout
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever),
                      title: const Text('회원탈퇴'),
                      onTap: () {
                        Navigator.pop(context); // Close the modal
                        print('회원탈퇴 selected');
                        // Handle account deletion
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('문의하기'),
                      onTap: () {
                        Navigator.pop(context); // Close the modal
                        print('문의하기 selected');
                        // Navigate to inquiry screen
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Appbar 표준 높이 지정
  @override
  Size get preferredSize => const Size.fromHeight((kToolbarHeight));
}