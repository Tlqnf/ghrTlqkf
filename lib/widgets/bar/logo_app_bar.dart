import 'package:flutter/material.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/login_screen.dart';
import 'package:pedal/screens/profile_setup_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Scaffold에게 자신의 높이가 몇 인지 알려주는 기능 포함 -> PreferredSizeWidget
class LogoBar extends StatelessWidget implements PreferredSizeWidget {
  const LogoBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    void showConfirmationDialog(String title, String content, VoidCallback onConfirm) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirm();
              },
            ),
          ],
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surface, // 스크롤 시 색상 변경 방지
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
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: authProvider.authState == AuthState.loggedIn ? [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.black),
                          title: const Text('프로필 수정', style: TextStyle(color: Colors.black)),
                          onTap: () {
                            Navigator.pop(context); // Close the modal
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileSetupPage(
                                  onSetupComplete: () => Navigator.pop(context),
                                  token: authProvider.token!,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.black),
                          title: const Text('로그아웃', style: TextStyle(color: Colors.black)),
                          onTap: () {
                            Navigator.pop(context); // Close the modal
                            showConfirmationDialog('로그아웃', '정말 로그아웃 하시겠습니까?', () async {
                              await UserApi.logoutUserProfile(authProvider.token!);
                              authProvider.logout();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    (Route<dynamic> route) => false,
                              );
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: Colors.black),
                          title: const Text('회원탈퇴', style: TextStyle(color: Colors.black)),
                          onTap: () async {
                            Navigator.pop(context); // Close the modal
                            showConfirmationDialog('회원탈퇴', '정말 탈퇴하시겠습니까? 모든 정보가 삭제됩니다.', () async {
                              try {
                                await UserApi.deleteUserProfile(authProvider.token!);
                                authProvider.logout();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                                  );
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                        (Route<dynamic> route) => false,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('회원탈퇴 중 오류가 발생했습니다: $e')),
                                  );
                                }
                              }
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.notifications, color: Colors.black),
                          title: const Text('공지사항', style: TextStyle(color: Colors.black)),
                          onTap: () async {
                            Navigator.pop(context); // Close the modal
                            // 공지사항 화면 만들기 -> 서버 확인 필요
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline, color: Colors.black),
                          title: const Text('문의하기', style: TextStyle(color: Colors.black)),
                          onTap: () async {
                            Navigator.pop(context); // Close the modal
                            final url = Uri.parse('http://pf.kakao.com/_fxoxoUn/chat');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              if(context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('카카오톡 오픈채팅방을 열 수 없습니다.')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    )
                );
              },
            );
          },
        ),
      ] : [],
    );
  }

  // Appbar 표준 높이 지정
  @override
  Size get preferredSize => const Size.fromHeight((kToolbarHeight));
}