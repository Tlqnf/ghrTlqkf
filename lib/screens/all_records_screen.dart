import 'package:flutter/material.dart';
import 'package:pedal/widgets/bar/logo_bar.dart';
import 'package:pedal/widgets/card/record_card.dart';
import 'package:pedal/screens/post_form_screen.dart';

class AllRecordsScreen extends StatelessWidget {
  const AllRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: LogoBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  '전체 기록',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () {
                    // Handle sorting by latest
                  },
                  child: const Text('최신순'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Dummy count for all records
              itemBuilder: (context, index) {
                return RecordCard(
                  routeName: '갤러리아 백화점 경로',
                  distance: '17.28 km',
                  time: '1시간 03분',
                  date: '2025.09.01',
                  image_url: '',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostFormScreen(
                      initialRouteName: '갤러리아 백화점 경로',
                      initialDistance: '17.28',
                      initialTime: '1시간 03분',
                    )));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
