import 'package:flutter/material.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/all_records_screen.dart';
import 'package:pedal/screens/payment_screen.dart';
import 'package:pedal/screens/post_form_screen.dart';
import 'package:pedal/widgets/my/post_list.dart';
import 'package:pedal/widgets/my/profile_header.dart';
import 'package:pedal/widgets/my/section_header.dart';
import 'package:pedal/mock/mock_card_summaries.dart';
import 'package:provider/provider.dart';
import 'package:pedal/screens/report_detail_screen.dart'; // Import the new screen
import 'package:pedal/models/card.dart'; // Import CardSummary

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(
                token: authProvider.token!,
                onRemoveAdsTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              SectionHeader(
                title: '내 기록',
                showMoreButton: true,
                onMoreTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllRecordsScreen(
                        bookmarked: false,
                        title: '내 전체 기록',
                      ),
                    ),
                  );
                },
              ),
              PostList(
                bookmarked: false,
                mockData: mockMyRecords,
                onItemTap: (CardSummary cardSummary) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailScreen(
                        time: '${cardSummary.timeHour.toString().padLeft(2, '0')}:${cardSummary.timeMinute.toString().padLeft(2, '0')}:00', // Assuming seconds are 00
                        distance: cardSummary.distance.toStringAsFixed(2),
                        maxSpeed: '24.7', // Hardcoded for now, as it's not in CardSummary
                        avgSpeed: '20.67', // Hardcoded for now, as it's not in CardSummary
                      ),
                    ),
                  );
                },
                onItemEdit: (CardSummary cardSummary) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostFormScreen(
                        postId: cardSummary.id,
                        reportId: cardSummary.id, // Assuming reportId is the same as postId for now
                        initialDistance: cardSummary.distance.toStringAsFixed(2),
                        initialTime: '${cardSummary.timeHour.toString().padLeft(2, '0')}:${cardSummary.timeMinute.toString().padLeft(2, '0')}:00',
                        mapImagePath: cardSummary.mapImageUrl,
                        routeName: cardSummary.title,
                        // tagList, title, content, imgUrls are not in CardSummary, so pass null
                      ),
                    ),
                  );
                },
              ), // Pass mock records
              const SizedBox(height: 16),
              SectionHeader(
                title: '북마크 경로',
                showMoreButton: true,
                onMoreTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllRecordsScreen(
                        bookmarked: true,
                        title: '북마크된 경로',
                      ),
                    ),
                  );
                },
              ),
              PostList(
                bookmarked: true,
                mockData: mockBookmarkedRoutes,
                onItemTap: null,
              ), // Pass mock bookmarked routes
            ],
          ),
        ),
      ),
    );
  }
}