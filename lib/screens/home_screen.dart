import 'package:flutter/material.dart';
import 'package:pedal/api/post_api.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/analyze.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/post/card/activity_card.dart';
import 'package:pedal/widgets/home/card/activity_summary_card.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Post>>? _postsFuture;
  Analyze? _analyze;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_postsFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        _postsFuture = PostApiService.getPosts(token);
        _fetchAnalyze(token);
      } else {
        _postsFuture = Future.error('Not authenticated');
      }
    }
  }

  Future<void> _fetchAnalyze(String token) async {
    final analyze = await UserApiService.analyzeUser(token);
    if (mounted) {
      setState(() {
        _analyze = analyze;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이번주 활동',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _analyze == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                            child: ActivitySummaryCard(
                              label: '활동 횟수',
                              value: '${_analyze?.routesTakenCount}',
                              unit: '회',
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '활동 시간',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    mainAxisSize: MainAxisSize
                                        .min, // Prevent row from expanding unnecessarily
                                    children: [
                                      Text(
                                          '${_analyze?.totalActivityTimeHours}',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red)),
                                      SizedBox(width: 4),
                                      Text('시간', style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 8),
                                      Text('${_analyze?.totalActivityTimeRemainingMinutes}',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red)),
                                      SizedBox(width: 4),
                                      Text('분', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                            child: ActivitySummaryCard(
                              label: '활동',
                              value: '${_analyze?.totalActivityDistanceKm}',
                              unit: 'km',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '커뮤니티',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
          ),
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
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ActivityCard(post: posts[index]);
                    },
                    childCount: posts.length,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
