import 'package:flutter/material.dart';
import 'package:pedal/widgets/card/record_card.dart';
import 'package:pedal/screens/all_records_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(),
            const SizedBox(height: 16),
            _SectionHeader(title: '내 기록', showMoreButton: true),
            _RecordList(),
            const SizedBox(height: 16),
            _SectionHeader(title: '북마크 경로', showMoreButton: true),
            _RecordList(), // Reusing for bookmarked routes for now
            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
      
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/google.png'), // Placeholder for user avatar
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Seprogramd',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '자전거 타는 고냥이',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // Handle logout
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showMoreButton;

  const _SectionHeader({
    required this.title,
    this.showMoreButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (showMoreButton)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AllRecordsScreen()));
              },
              child: const Text('더보기'),
            ),
        ],
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner ListView
      itemCount: 4, // Dummy count
      itemBuilder: (context, index) {
        return const RecordCard(
          routeName: '갤러리아 백화점 경로',
          distance: '17.28 km',
          time: '1시간 03분',
          date: '2025.09.01',
        );
      },
    );
  }
}
