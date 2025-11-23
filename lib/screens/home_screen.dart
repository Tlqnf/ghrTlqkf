import 'package:flutter/material.dart';
import 'package:pedal/api/calendar_api.dart';
import 'package:pedal/api/post_api.dart';
import 'package:pedal/models/calendar_summary.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/calendar_daily_log_screen.dart';
import 'package:pedal/widgets/post/card/activity_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Post>>? _postsFuture;
  List<RideStamp>? _rideStamps;
  int _consecutiveDays = 0;
  bool _isLoadingStamps = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_postsFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        _postsFuture = PostApi.getPosts(token);
        _fetchCalendarData(token);
      } else {
        _postsFuture = Future.error('Not authenticated');
      }
    }
  }

  Future<void> _fetchCalendarData(String token) async {
    try {
      final stamps = await CalendarApi.fetchMonthStampList(token);
      if (mounted) {
        setState(() {
          _rideStamps = stamps;
          _consecutiveDays = _calculateConsecutiveDays(stamps);
          _isLoadingStamps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStamps = false;
        });
      }
    }
  }

  int _calculateConsecutiveDays(List<RideStamp> stamps) {
    if (stamps.isEmpty) return 0;

    final uniqueDates = stamps
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet();

    final today = DateTime.now();
    var currentDate = DateTime(today.year, today.month, today.day);

    if (!uniqueDates.contains(currentDate)) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    if (!uniqueDates.contains(currentDate)) {
      return 0;
    }

    int streak = 0;
    while (uniqueDates.contains(currentDate)) {
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<void> _refreshData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() {
      _isLoadingStamps = true;
      _postsFuture = PostApi.getPosts(token);
    });
    await _fetchCalendarData(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
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
                      _isLoadingStamps
                          ? const Center(child: CircularProgressIndicator())
                          : _buildStreakWidget(),
                    ],
                  ),
                ),
              ]),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
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

  Widget _buildStreakWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_outlined, size: 60),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_consecutiveDays일 연속 활동',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              '활동 더보기',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.normal
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RidingStatsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildWeeklyDays(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final days = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
    final dayNames = ['일', '월', '화', '수', '목', '금', '토'];

    final activeDays =
        _rideStamps
            ?.map((s) => DateTime(s.date.year, s.date.month, s.date.day))
            .toSet() ??
        {};

    return Row(
      children: List.generate(7, (index) {
        final day = days[index];
        final dayName = dayNames[index];
        final isActive = activeDays.contains(day);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? Colors.black : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                dayName,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
