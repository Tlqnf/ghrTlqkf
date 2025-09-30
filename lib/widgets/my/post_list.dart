import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/widgets/post/card/post_card.dart';

class PostList extends StatefulWidget {
  final bool bookmarked;
  final List<Post>? postData; // Add optional mock data parameter
  final Function(Post)? onItemTap; // Add this
  final Function(Post)? onItemEdit; // Add this

  const PostList({
    super.key,
    required this.bookmarked,
    this.postData,
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
    final items = widget.postData!;
    if (widget.postData != null) {
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
            routeName: widget.bookmarked ? p.title : p.routeName,
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
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}