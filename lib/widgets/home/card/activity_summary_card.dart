import 'package:flutter/material.dart';

class ActivitySummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String? minute;

  const ActivitySummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.minute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.grey[100], // 카드 배경색
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black, // 제목 색상
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary, // 값 색상
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black, // 단위 색상
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
