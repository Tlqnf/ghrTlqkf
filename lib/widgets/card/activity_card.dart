
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/widgets/modal/comment_modal.dart';

class ActivityCard extends StatefulWidget {
  final Post post;
  const ActivityCard({super.key, required this.post});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = false; 
    _likeCount = widget.post.likeCount;
  }

  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR').format(widget.post.createdAt.toLocal());

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: theme.colorScheme.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ${widget.post.userId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.post.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(widget.post.content),
            const SizedBox(height: 16),
            if (widget.post.images.isNotEmpty && widget.post.images.first['url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: (widget.post.images.first['url'] as String).startsWith('http')
                    ? Image.network(
                        widget.post.images.first['url'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(height: 200, child: Center(child: Text('이미지를 불러올 수 없습니다.'))),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                        },
                      )
                    : const SizedBox(height: 200, child: Center(child: Text('잘못된 이미지 URL입니다.'))), // Fallback for invalid URL
              ),
            const SizedBox(height: 16),
            // TODO: Implement map view using post.route
            // Container(
            //   height: 150,
            //   decoration: BoxDecoration(
            //     color: Colors.grey[300],
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: const Center(
            //     child: Text('Map Placeholder'),
            //   ),
            // ),
            // const SizedBox(height: 16),
            Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: _isLiked ? theme.colorScheme.secondary : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(_likeCount.toString()),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.7,
                        maxChildSize: 0.9,
                        minChildSize: 0.4,
                        builder: (context, scrollController) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16.0),
                              topRight: Radius.circular(16.0),
                            ),
                          ),
                          child: const CommentModal(),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.chat_bubble_outline),
                      SizedBox(width: 4),
                      Text('0'), // TODO: Replace with actual comment count
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.bookmark_border),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ));
  }
}
