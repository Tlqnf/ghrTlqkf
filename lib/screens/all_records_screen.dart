import 'package:flutter/material.dart';
import 'package:pedal/widgets/my/post_list.dart'; // New import
import 'package:pedal/mock/mock_card_summaries.dart'; // New import
import 'package:pedal/models/card.dart'; // New import
import 'package:pedal/screens/report_detail_screen.dart'; // New import
import 'package:pedal/screens/post_form_screen.dart'; // Used in PostList callbacks

class AllRecordsScreen extends StatelessWidget {
  final bool bookmarked;
  final String title;

  const AllRecordsScreen({
    super.key,
    required this.bookmarked,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final List<CardSummary> data = bookmarked ? mockBookmarkedRoutes : mockMyRecords;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
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
            child: PostList(
              bookmarked: bookmarked,
              mockData: data,
              onItemTap: bookmarked ? null : (CardSummary cardSummary) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      time: '${cardSummary.timeHour.toString().padLeft(2, '0')}:${cardSummary.timeMinute.toString().padLeft(2, '0')}:00',
                      distance: cardSummary.distance.toStringAsFixed(2),
                      maxSpeed: '24.7', // Hardcoded for now
                      avgSpeed: '20.67', // Hardcoded for now
                    ),
                  ),
                );
              },
              onItemEdit: bookmarked ? null : (CardSummary cardSummary) { // Only allow edit for non-bookmarked (my records)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostFormScreen(
                      postId: cardSummary.id,
                      initialDistance: cardSummary.distance.toStringAsFixed(2),
                      initialTime: '${cardSummary.timeHour.toString().padLeft(2, '0')}:${cardSummary.timeMinute.toString().padLeft(2, '0')}:00',
                      mapImagePath: cardSummary.mapImageUrl,
                      routeName: cardSummary.title,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
