import 'package:flutter/material.dart';
import 'package:pedal/models/calendar_summary.dart';
import 'package:pedal/widgets/calendar/card/riding_calendar_card.dart';

class MedalAndCalendarSection extends StatelessWidget {
  final int getMedal;
  final int getMonthDay;
  final int avgMedalIndex;
  final int growRate;
  final List<RideStamp> rideData;

  const MedalAndCalendarSection({
    super.key,
    required this.getMedal,
    required this.getMonthDay,
    required this.avgMedalIndex,
    required this.growRate,
    required this.rideData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MedalSummaryCard(
          getMedal: getMedal,
          getMonthDay: getMonthDay,
          avgMedalIndex: avgMedalIndex,
          growRate: growRate,
        ),
        const SizedBox(height: 16),
        RidingCalendarCard(rideData: rideData),
      ],
    );
  }
}

class MedalInfo {
  final String name;
  final String imagePath;
  const MedalInfo(this.name, this.imagePath);
}

//
// 🥇 이번 달 메달 취득 내역 카드
//
class MedalSummaryCard extends StatelessWidget {
  final int getMedal;
  final int getMonthDay;
  final int avgMedalIndex;
  final int growRate;

  const MedalSummaryCard({
    super.key,
    required this.getMedal,
    required this.getMonthDay,
    required this.avgMedalIndex,
    required this.growRate,
  });

  static const List<MedalInfo> medalInfoList = [
    MedalInfo("동메달", "assets/image/medal/bronze.png"), // index 0
    MedalInfo("은메달", "assets/image/medal/silver.png"), // index 1
    MedalInfo("금메달", "assets/image/medal/gold.png"), // index 2
    MedalInfo("다이아몬드", "assets/image/medal/diamond.png"), // index 3
    MedalInfo("마스터", "assets/image/medal/master.png"), // index 4
  ];

  @override
  Widget build(BuildContext context) {
    if (avgMedalIndex < 0 || avgMedalIndex > medalInfoList.length) {
      // Handle invalid index, perhaps return a default state
      return const SizedBox.shrink(); // Or some error/default widget
    }

    final medalInfo = avgMedalIndex == 0
        ? null
        : medalInfoList[avgMedalIndex - 1];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 메달 취득 내역',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '지난 달에 비해 $growRate% 성장했어요!',
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '메달 $getMedal / $getMonthDay',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      '평균 달성 메달',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (medalInfo != null) ...[
                      const SizedBox(width: 4),
                      Image.asset(medalInfo.imagePath, width: 18, height: 18),
                      Text(
                        ' ${medalInfo.name}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        ' 메달 없음',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
