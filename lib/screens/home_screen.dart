import 'package:flutter/material.dart';
import 'package:pedal/api/post_api.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/analyze.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/calendar_daily_log_screen.dart';
import 'package:pedal/widgets/post/card/activity_card.dart';
import 'package:pedal/widgets/home/card/activity_summary_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Post>>? _postsFuture;
  Analyze? _analyze;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_postsFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        _postsFuture = PostApi.getPosts(token);
        _fetchAnalyze(token);
      } else {
        _postsFuture = Future.error('Not authenticated');
      }
    }
  }

  Future<void> _fetchAnalyze(String token) async {
    final analyze = await UserApi.analyzeUser(token);
    if (mounted) {
      setState(() {
        _analyze = analyze;
      });
    }
  }

  Future<void> _refreshData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() {
      _postsFuture = PostApi.getPosts(token);
    });
    await _fetchAnalyze(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        // Pull-to-Refresh 적용
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '이번주 활동',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RidingStatsScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              '더보기',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _analyze == null
                          ? const Center(child: Text("활동 요약 데이터를 불러오는 중입니다..."))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    child: ActivitySummaryCard(
                                      label: '활동 횟수',
                                      value:
                                          '${_analyze?.routesTakenCount ?? 0}',
                                      unit: '회',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    child: ActivitySummaryCard(
                                      label: '활동 시간',
                                      value:
                                          _analyze
                                              ?.totalActivityTimeFormatted ??
                                          '00:00:00',
                                      unit: '',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    child: ActivitySummaryCard(
                                      label: '활동 거리',
                                      value:
                                          _analyze?.totalActivityDistanceKm
                                              .toStringAsFixed(2) ??
                                          '0.00',
                                      unit: 'km',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ]),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            FutureBuilder<List<Post>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text('No posts found.')),
                  );
                } else {
                  final posts = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return ActivityCard(post: posts[index]);
                    }, childCount: posts.length),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
