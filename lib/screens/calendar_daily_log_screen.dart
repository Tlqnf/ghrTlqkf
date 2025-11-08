import 'package:flutter/cupertino.dart';
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
      final token = Provider.of<AuthProvider>(context, listen: false).token!=null? Provider.of<AuthProvider>(context, listen: false).token:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTAxNDY2fQ.xBgQTC9zWmDBlL5VyXCylbmfdR0f37nr7MBgoOgG9fQ";
      if (token != null) {
        _dailySummaryFuture = ReportApi.fetchDailySummary(token, DateTime.now());
        _userLevelFuture = ReportApi.fetchUserLevel(token);
      } else {
        _dailySummaryFuture = Future.error('Not authenticated');
        _userLevelFuture = Future.error('Not authenticated');
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB9E9FF), // 배경색 변경
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('일지'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
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

                            return SizedBox(
                              child: RidingSummaryWidget(
                                distanceKm: dailySummary.totalActivityDistanceKm,
                                calories: dailySummary.totalKal,
                                rank: userLevel.lev,
                              ),
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
    );
  }

  // ✅ 탭 버튼 위젯
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