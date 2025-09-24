import 'package:flutter/material.dart';

class NavigationListModal extends StatelessWidget {
  final ScrollController scrollController;
  const NavigationListModal({super.key, required this.scrollController });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 위쪽 회색 핸들바
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '내 경로',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("현재 네비게이션은 개발 중에 있습니다.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                      Text("빠른 시일 내에 여러분들께 선보일 수 있도록 하겠습니다."),
                    ],
                  ),
                ),
              ],
            ),
            // ListView.builder(
            //   physics: const NeverScrollableScrollPhysics(), // Handled by SingleChildScrollView
            //   shrinkWrap: true,
            //   itemCount: 2, // Dummy data for "My Routes"
            //   itemBuilder: (context, index) {
            //     return Padding(
            //       padding: const EdgeInsets.symmetric(),
            //       child: PostCard(
            //         routeName: '갤러리아 백화점 경로',
            //         distance: '17.28 km',
            //         time: '01:03:23',
            //         date: '2025.09.01',
            //         onTap: () {
            //           debugPrint('My Route ${index + 1} tapped!');
            //         },
            //       ),
            //     );
            //   },
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(),
            //   child: TextButton(
            //     onPressed: () {
            //       debugPrint('2개 경로 더보기 tapped!');
            //     },
            //     child: Text(
            //       '2개 경로 더보기',
            //       style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16),
            //     ),
            //   ),
            // ),
            // const Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            //   child: Text(
            //     '저장한 경로',
            //     style: TextStyle(
            //       fontSize: 20,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            // ListView.builder(
            //   physics: const NeverScrollableScrollPhysics(), // Handled by SingleChildScrollView
            //   shrinkWrap: true,
            //   itemCount: 2, // Dummy data for "Saved Routes"
            //   itemBuilder: (context, index) {
            //     return Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            //       child: PostCard(
            //         routeName: '시청역 근처 경로',
            //         distance: '9.98 km',
            //         time: '47분',
            //         user: 'Seprogramd${index + 1}',
            //         onTap: () {
            //           debugPrint('Saved Route ${index + 1} tapped!');
            //         },
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}