import 'package:flutter/material.dart';

class TodayMessageCard extends StatelessWidget {
  final int calories;

  const TodayMessageCard({super.key, required this.calories});

  Map<String, String> _getFoodInfo() {
    if (calories >= 2000) {
      return {'name': '치킨 한 마리', 'image': 'assets/image/kal_food/chicken.png'};
    } else if (calories >= 1200) {
      return {'name': '라면 두 그릇', 'image': 'assets/image/kal_food/ramen.png'};
    } else if (calories >= 600) {
      return {'name': '떡볶이 1인분', 'image': 'assets/image/kal_food/tteokbokki.png'};
    } else if (calories >= 450) {
      return {'name': '김밥 한 개', 'image': 'assets/image/kal_food/gimbap.png'};
    } else if (calories >= 250) {
      return {'name': '샌드위치 한 개', 'image': 'assets/image/kal_food/sandwich.png'};
    } else if (calories > 0) {
      return {'name': '가벼운 간식', 'image': 'assets/image_mock.png'}; // 400 미만일 때
    } else {
      return {'name': '...', 'image': 'assets/image_mock.png'}; // 0일 때
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodInfo = _getFoodInfo();
    final foodName = foodInfo['name']!;
    final foodImage = foodInfo['image']!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                foodImage,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지가 없을 경우 목업 이미지로 대체
                  return Image.asset(
                    'assets/Logo.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16), // Add vertical spacing
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '오늘 ',
                  style: TextStyle(fontSize: 16),
                ),
                TextSpan(
                  text: '$foodName ',
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const TextSpan(
                  text: '이상을 라이딩에 불태웠어요!',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            textAlign: TextAlign.center, // Center the text
          ),
        ],
      ),
    );
  }
}