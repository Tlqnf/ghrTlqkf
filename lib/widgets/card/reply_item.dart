import 'package:flutter/material.dart';

class ReplyItem extends StatelessWidget {
  const ReplyItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, top: 12.0, bottom: 12.0), // Added left padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16, // Slightly smaller avatar for replies
            backgroundColor: Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ReplyUser', // Dummy reply user
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                    '네! 언제든지 환영합니다! 같이 라이딩하면 정말 즐거울 것 같아요!'), // Dummy reply content
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.thumb_up_alt_outlined, size: 14), // Slightly smaller icon
                    const SizedBox(width: 4),
                    const Text('123'), // Dummy like count
                    const SizedBox(width: 16),
                    const Text('답글 달기'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
