import 'package:flutter/material.dart';
import 'package:pedal/widgets/report/riding_process_bar.dart';

class RidingSummaryWidget extends StatelessWidget {
  final double distanceKm;
  final int calories;
  final String rank;

  const RidingSummaryWidget({
    super.key,
    required this.distanceKm,
    required this.calories,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFadd455), // 하늘색 배경 (필요시 수정 가능)
            image: DecorationImage(
              image: AssetImage('assets/image/report_background.png'), // 배경 구름 이미지(선택)
              fit: BoxFit.fitWidth, // 이미지 비율을 유지하면서 가로로 꽉 채우도록 수정
              alignment: Alignment.topCenter, // 이미지를 상단에 고정
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 30,),
              const Text(
                '오늘도 와주셨군요!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${distanceKm.toStringAsFixed(2)} km',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$calories kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Text(
                          '등급',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$rank 등급",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5DB075), // 연두색 포인트
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // 원하는 만큼 공간 추가
              RidingProgressBar(
                currentKm: distanceKm,
                maxKm: 15,
                medalDistances: [3, 6, 9, 12, 15],
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 30, // Height of the gradient fade
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0), // Start transparent
                    Colors.white.withValues(alpha: 0.8), // Fade to white
                    Colors.white, // Fully white at the bottom
                  ],
                  stops: const [0.5, 2.5, 5.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
