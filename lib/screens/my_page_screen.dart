import 'package:flutter/material.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/all_records_screen.dart';
import 'package:pedal/screens/payment_screen.dart';
import 'package:pedal/screens/post_form_screen.dart';
import 'package:pedal/widgets/my/post_list.dart';
import 'package:pedal/widgets/my/profile_header.dart';
import 'package:pedal/widgets/my/section_header.dart';
import 'package:provider/provider.dart';
import 'package:pedal/screens/report_detail_screen.dart';
import 'package:pedal/models/post.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late Future<List<Post>> _recentPostsFuture;
  late Future<List<Post>> _recentBookmarksFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _recentPostsFuture = UserApi.getRecentPosts(authProvider.token!);
    _recentBookmarksFuture = UserApi.getRecentBookmarks(authProvider.token!);
  }

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
              FutureBuilder<List<Post>>(
                future: _recentPostsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data'));
                  }
                  return PostList(
                    bookmarked: false,
                    mockData: snapshot.data!,
                    onItemTap: (Post post) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportDetailScreen(
                            reportId: post.reportId,
                          ),
                        ),
                      );
                    },
                    onItemEdit: (Post post) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostFormScreen(
                            postId: post.id,
                            reportId: post.id, // Assuming reportId is the same as postId for now
                            initialDistance: post.distance.toStringAsFixed(2),
                            initialTime: post.time,
                            mapImagePath: post.mapImageUrl,
                            routeName: post.title,
                            // tagList, title, content, imgUrls are not in Post, so pass null
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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
              FutureBuilder<List<Post>>(
                future: _recentBookmarksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data'));
                  }
                  return PostList(
                    bookmarked: true,
                    mockData: snapshot.data!,
                    onItemTap: null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
