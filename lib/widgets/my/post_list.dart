import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/post/card/post_card.dart';
import 'package:provider/provider.dart';

class PostList extends StatefulWidget {
  final bool bookmarked;
  final List<Post>? mockData; // Add optional mock data parameter
  final Function(Post)? onItemTap; // Add this
  final Function(Post)? onItemEdit; // Add this

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
          final p = items[index];

          final distance = _formatDistance(p.distance);
          final date = DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR')
              .format(p.createdAt.toLocal());
          final imageUrl = p.mapImageUrl;

          return PostCard(
            routeName: p.routeName,
            distance: distance,
            time: p.time,
            date: date,
            imageUrl: imageUrl,
            onTap: widget.onItemTap != null ? () => widget.onItemTap!(p) : null, // Pass tap event
            onEdit: widget.onItemEdit != null ? () => widget.onItemEdit!(p) : null, // Pass edit event
          );
        },
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return FutureBuilder<List<Post>>(
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
            final p = items[index];

            final distance = _formatDistance(p.distance);
            final time = p.time;
            final date = DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR')
                .format(p.createdAt.toLocal());
            final imageUrl = p.mapImageUrl;

            return PostCard(
              routeName: p.routeName,
              distance: distance,
              time: time,
              date: date,
              imageUrl: imageUrl, // MapImageUrl
              onTap: widget.onItemTap != null ? () => widget.onItemTap!(p) : null, // Pass tap event
              onEdit: widget.onItemEdit != null ? () => widget.onItemEdit!(p) : null, // Pass edit event
            );
          },
        );
      },
    );
  }
}