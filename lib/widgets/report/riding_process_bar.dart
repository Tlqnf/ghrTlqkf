import 'package:flutter/material.dart';

class RidingProgressBar extends StatefulWidget {
  final double currentKm; // 현재 주행 거리
  final double maxKm; // 전체 목표 거리 (ex. 15)
  final List<double> medalDistances; // 각 메달 위치 (ex. [3, 6, 9, 12, 15])

  const RidingProgressBar({
    super.key,
    required this.currentKm,
    required this.maxKm,
    required this.medalDistances,
  });

  @override
  State<RidingProgressBar> createState() => _RidingProgressBarState();
}

class _RidingProgressBarState extends State<RidingProgressBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBicycle());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBicycle() {
    const double pixelsPerKm = 60.0;
    const double startOffset = 50.0;

    final double displayMaxKm = widget.medalDistances.isNotEmpty
        ? widget.medalDistances.last + 1.5
        : widget.maxKm;
    final double progressWidth = widget.currentKm * pixelsPerKm;
    final double maxProgressWidth = displayMaxKm * pixelsPerKm;
    final double clampedProgressWidth = progressWidth.clamp(
      0.0,
      maxProgressWidth,
    );
    final bool isCompleted = widget.currentKm >= displayMaxKm;

    final screenWidth = MediaQuery.of(context).size.width;
    double bicycleXPosition;

    if (isCompleted) {
      bicycleXPosition = startOffset + maxProgressWidth;
    } else {
      bicycleXPosition = startOffset + clampedProgressWidth;
    }

    // 자전거 아이콘이 화면 중앙에 오도록 스크롤 위치 계산
    final targetScrollOffset = bicycleXPosition - (screenWidth / 2);

    // 계산된 위치로 스크롤 이동
    _scrollController.jumpTo(
      targetScrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double pixelsPerKm = 60.0; // 1km당 픽셀
    const double barHeight = 20.0; // 게이지 두께
    const double startOffset = 50.0; // 시작 여백

    final double displayMaxKm = widget.medalDistances.isNotEmpty
        ? widget.medalDistances.last + 1.5
        : widget.maxKm;

    final double totalWidth = displayMaxKm * pixelsPerKm + startOffset * 2;
    final double progressWidth = widget.currentKm * pixelsPerKm;
    final double maxProgressWidth = displayMaxKm * pixelsPerKm;
    final double clampedProgressWidth = progressWidth.clamp(
      0.0,
      maxProgressWidth,
    );
    final bool isCompleted = widget.currentKm >= displayMaxKm;

    String getMedalImage(int index) {
      switch (index) {
        case 0:
          return 'assets/image/medal/bronze.png';
        case 1:
          return 'assets/image/medal/silver.png';
        case 2:
          return 'assets/image/medal/gold.png';
        case 3:
          return 'assets/image/medal/diamond.png';
        case 4:
          return 'assets/image/medal/master.png';
        default:
          return 'assets/image/medal/bronze.png';
      }
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        height: 150, // Increased height
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // ... (Rest of the Stack children remain the same)
            Positioned(
              top: 75,
              left: startOffset,
              child: Container(
                width: maxProgressWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              top: 75,
              left: startOffset,
              child: Container(
                width: clampedProgressWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF4AA8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            for (int i = 0; i < widget.medalDistances.length; i++) ...[
              Positioned(
                top: 0,
                left:
                    startOffset + (widget.medalDistances[i] * pixelsPerKm) - 32,
                child: Image.asset(getMedalImage(i), width: 65),
              ),
              Positioned(
                top: 120, // Moved down
                left:
                    startOffset + (widget.medalDistances[i] * pixelsPerKm) - 32,
                width: 65,
                child: Text(
                  '${widget.medalDistances[i].toInt()} km',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                ),
              ),
              Positioned(
                top: 70, // Centered on gauge
                left:
                    startOffset +
                    (widget.medalDistances[i] * pixelsPerKm) -
                    15, // Adjusted offset
                child: Container(
                  width: 30, // Increased size
                  height: 30, // Increased size
                  decoration: BoxDecoration(
                    color: widget.currentKm >= widget.medalDistances[i]
                        ? const Color(0xFF4AA8FF)
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
            Positioned(
              left: isCompleted
                  ? startOffset + maxProgressWidth - 20
                  : startOffset + clampedProgressWidth - 20,
              top: 40,
              child: Image.asset('assets/image/medal/bicycle.png', width: 30),
            ),
            Positioned(
              left: 10,
              top: 45,
              child: Image.asset('assets/image/medal/start.png', width: 80),
            ),
            if (widget.medalDistances.isNotEmpty &&
                widget.currentKm >= widget.medalDistances.last)
              Positioned(
                top: 110,
                left: isCompleted
                    ? startOffset + maxProgressWidth - 40
                    : startOffset + clampedProgressWidth - 40,
                width: 80,
                child: Text(
                  '${widget.currentKm.toStringAsFixed(1)} km',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4AA8FF),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
