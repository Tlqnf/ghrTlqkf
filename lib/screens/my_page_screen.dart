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
      resizeToAvoidBottomInset: false,
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
                    return const Center(child: Text('현재 저장한 기록이 없습니다.'));
                  }
                  return PostList(
                    bookmarked: false,
                    postData: snapshot.data!,
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
                            postData: post,
                            routeId: post.routeId,
                            mapImagePath: post.mapImageUrl,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
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
                    return const Center(child: Text('현재 북마크한 경로가 없습니다.'));
                  }
                  return PostList(
                    bookmarked: true,
                    postData: snapshot.data!,
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
