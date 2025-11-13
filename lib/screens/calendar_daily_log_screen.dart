import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/report_api.dart';
import '../models/calendar_summary.dart';
import '../providers/auth_provider.dart';
import '../widgets/report/ride_summery_widget.dart';
import 'calendar_screen.dart';
import 'daily_log_screen.dart';

class RidingStatsScreen extends StatefulWidget {
  const RidingStatsScreen({super.key});

  @override
  State<RidingStatsScreen> createState() => _RidingStatsScreenState();
}


class _RidingStatsScreenState extends State<RidingStatsScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  Future<DailySummary>? _dailySummaryFuture;
  Future<UserLevel>? _userLevelFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dailySummaryFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
        _dailySummaryFuture = ReportApi.fetchDailySummary(token!, DateTime.now());
        _userLevelFuture = ReportApi.fetchUserLevel(token);
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const double headerHeight = 70; // 원하면 조절

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              height: headerHeight + topPadding,
              width: double.infinity,
              color: const Color(0xFFB9E9FF),
              padding: EdgeInsets.only(top: topPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '일지',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ 🔹 Expanded로 기존 내용 그대로 표시
            Expanded(
              child: NestedScrollView(
                physics: const BouncingScrollPhysics(),

                // 🔻 NestedScrollView가 custom header 아래에서 시작되도록 padding 추가
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(child: SizedBox(height: 0)),
                    SliverToBoxAdapter(
                      child: (_dailySummaryFuture == null || _userLevelFuture == null)
                          ? const Center(child: CircularProgressIndicator())
                          : FutureBuilder<List<Object>>(
                        future: Future.wait([_dailySummaryFuture!, _userLevelFuture!]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData) {
                            return const Center(child: Text('No data'));
                          } else {
                            final dailySummary = snapshot.data![0] as DailySummary;
                            final userLevel = snapshot.data![1] as UserLevel;

                            return RidingSummaryWidget(
                              distanceKm: dailySummary.totalActivityDistanceKm,
                              calories: dailySummary.totalKal,
                              rank: userLevel.lev,
                            );
                          }
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Container(
                            width: 200,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildTabButton("캘린더", 0),
                                _buildTabButton("통계", 1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ];
                },

                body: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  children: const [
                    CalendarScreen(),
                    StatsScreen(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildTabButton(String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4285F4) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}