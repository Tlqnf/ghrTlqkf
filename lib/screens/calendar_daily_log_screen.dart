import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pedal/api/report_api.dart';
import 'package:pedal/models/calendar_summary.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/report/ride_summery_widget.dart';
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

  // Future를 분리하여 개별 관리
  Future<DailySummary>? _dailySummaryFuture;
  Future<UserLevel>? _userLevelFuture;

  // 캐시된 데이터 (로딩 완료 후)
  DailySummary? _cachedDailySummary;
  UserLevel? _cachedUserLevel;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      CalendarScreen(),
      StatsScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dailySummaryFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      _dailySummaryFuture = ReportApi.fetchDailySummary(token!, DateTime.now());
      _userLevelFuture = ReportApi.fetchUserLevel(token);

      // 데이터 캐싱
      _dailySummaryFuture!.then((value) => _cachedDailySummary = value);
      _userLevelFuture!.then((value) => _cachedUserLevel = value);
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
    const double headerHeight = 70;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 헤더를 RepaintBoundary로 감싸서 재빌드 최소화
            RepaintBoundary(
              child: Container(
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
            ),

            Expanded(
              child: NestedScrollView(
                physics: const BouncingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // Summary 위젯
                    SliverToBoxAdapter(
                      child: _buildSummarySection(),
                    ),
                    // 탭 버튼
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
                  children: _pages,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary 섹션을 별도 메서드로 분리
  Widget _buildSummarySection() {
    // 캐시된 데이터가 있으면 즉시 표시 (재빌드 시 깜빡임 방지)
    if (_cachedDailySummary != null && _cachedUserLevel != null) {
      return RepaintBoundary(
        child: RidingSummaryWidget(
          distanceKm: _cachedDailySummary!.totalActivityDistanceKm,
          calories: _cachedDailySummary!.totalKal,
          rank: _cachedUserLevel!.lev,
        ),
      );
    }

    // 로딩 중일 때만 FutureBuilder 사용
    if (_dailySummaryFuture == null || _userLevelFuture == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<List<Object>>(
      future: Future.wait([_dailySummaryFuture!, _userLevelFuture!]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No data')),
          );
        }

        final dailySummary = snapshot.data![0] as DailySummary;
        final userLevel = snapshot.data![1] as UserLevel;

        // RepaintBoundary를 실제 위젯에만 적용
        return RepaintBoundary(
          child: RidingSummaryWidget(
            distanceKm: dailySummary.totalActivityDistanceKm,
            calories: dailySummary.totalKal,
            rank: userLevel.lev,
          ),
        );
      },
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