import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool showMoreButton;
  final VoidCallback? onMoreTap; // New parameter

  const SectionHeader({
    super.key,
    required this.title,
    this.showMoreButton = false,
    this.onMoreTap, // Initialize new parameter
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (showMoreButton)
            TextButton(
              onPressed: onMoreTap, // Use the new callback
              child: const Text('더보기'),
            ),
        ],
      ),
    );
  }
}
