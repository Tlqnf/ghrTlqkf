
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pedal/api/user_api_service.dart';
import 'package:pedal/models/analyze.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/widgets/card/activity_card.dart';
import 'package:pedal/widgets/card/activity_summary_card.dart';

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Post>> _postsFuture;
  Analyze? _analyze;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
    _fetchAnalyze();
  }


  Future<List<Post>> _fetchPosts() async {
    final response = await http.get(
      Uri.parse('http://172.30.1.14:8080/post'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> _fetchAnalyze() async {
    final analyze = await UserApiService.analyzeUser(widget.token);
    setState(() {
      _analyze = analyze;
    });
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                            child: ActivitySummaryCard(
                              label: '활동 횟수',
                              value: '${_analyze?.routes_taken_count}',
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
                                          '${_analyze?.total_activity_time_hours}',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red)),
                                      SizedBox(width: 4),
                                      Text('시간', style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 8),
                                      Text('${_analyze?.total_activity_time_remaining_minutes}',
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
                              value: '${_analyze?.total_activity_distance_km}',
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
                      return ActivityCard(post: posts[index],token: widget.token,);
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
