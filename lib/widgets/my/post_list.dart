import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/card.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/post/card/post_card.dart';
import 'package:provider/provider.dart';

class PostList extends StatefulWidget {
  final bool bookmarked;
  final List<CardSummary>? mockData; // Add optional mock data parameter
  final Function(CardSummary)? onItemTap; // Add this
  final Function(CardSummary)? onItemEdit; // Add this

  const PostList({
    super.key,
    required this.bookmarked,
    this.mockData,
    this.onItemTap,
    this.onItemEdit,
  });

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  String _formatDistance(double km) => '${km.toStringAsFixed(2)} km';

  String _formatTime(int h, int m) {
    final String hours = h.toString().padLeft(2, '0');
    final String minutes = m.toString().padLeft(2, '0');
    const String seconds = '00'; // Assuming seconds are always 00 as not provided
    return '$hours:$minutes:$seconds';
  }

  String _formatDate(String raw) {
    final parsed = DateTime.parse(raw).toLocal();
    return DateFormat('yyyy.MM.dd').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mockData != null) {
      final items = widget.mockData!;
      if (items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text('최근 기록이 없습니다.'),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final c = items[index];

          final distance = _formatDistance(c.distance);
          final time = _formatTime(c.timeHour, c.timeMinute);
          final date = _formatDate(c.createdAt);
          final imageUrl = c.mapImageUrl;

          return PostCard(
            routeName: c.title,
            distance: distance,
            time: time,
            date: date,
            imageUrl: imageUrl,
            onTap: widget.onItemTap != null ? () => widget.onItemTap!(c) : null, // Pass tap event
            onEdit: widget.onItemEdit != null ? () => widget.onItemEdit!(c) : null, // Pass edit event
          );
        },
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return FutureBuilder<List<CardSummary>>(
      future: widget.bookmarked
            ? UserApi.getRecentPosts(authProvider.token!)
            : UserApi.getRecentBookmarks(authProvider.token!),

      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('불러오기 실패: ${snap.error}'),
          );
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('최근 기록이 없습니다.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length, // 4개 표시
          itemBuilder: (context, index) {
            final c = items[index];

            final distance = _formatDistance(c.distance);
            final time = _formatTime(c.timeHour, c.timeMinute);
            final date = _formatDate(c.createdAt);
            final imageUrl = c.mapImageUrl;

            return PostCard(
              routeName: c.title, // post에 routeName 따로 사용
              distance: distance,
              time: time,
              date: date,
              imageUrl: imageUrl, // MapImageUrl
              onTap: widget.onItemTap != null ? () => widget.onItemTap!(c) : null, // Pass tap event
              onEdit: widget.onItemEdit != null ? () => widget.onItemEdit!(c) : null, // Pass edit event
            );
          },
        );
      },
    );
  }
}