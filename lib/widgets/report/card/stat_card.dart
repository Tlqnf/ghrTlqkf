import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color textColor;
  final double? progress; // Nullable progress value

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.textColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Center(
            child: progress != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: 1.0, // Background track
                          strokeWidth: 10,
                          color: color.withValues(alpha: 0.2),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: progress, // Actual progress
                          strokeWidth: 10,
                          color: color,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 10),
                    ),
                    child: Center(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
