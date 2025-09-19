
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/api/user_api_service.dart';
import 'package:pedal/widgets/modal/comment_modal.dart';

class ActivityCard extends StatefulWidget {
  final Post post;
  final String token;
  const ActivityCard({super.key, required this.post, required this.token});

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

  Future<void> _addThumbsUp(int postId) =>
      UserApiService.addThumbsUp(widget.token, postId);

  Future<void> _removeThumbsUp(int postId) =>
      UserApiService.removeThumbsUp(widget.token, postId);

  void _toggleLike() async {
    final prevLiked = _isLiked;
    final prevCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await _addThumbsUp(widget.post.id);
      } else {
        await _removeThumbsUp(widget.post.id);
      }
    } catch (e) {
      // 실패 시 롤백
      setState(() {
        _isLiked = prevLiked;
        _likeCount = prevCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR')
        .format(widget.post.createdAt.toLocal());

    final hasImage = widget.post.images.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
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

            // 이미지 (첫 장만)
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  widget.post.images.first, // ← 문자열 URL
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('이미지를 불러올 수 없습니다.'))),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()));
                  },
                ),
              ),

            const SizedBox(height: 16),

            // 액션
            Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        color: _isLiked
                            ? theme.colorScheme.secondary
                            : Colors.black54,
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
                  child: const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline),
                      SizedBox(width: 4),
                      Text('0'), // TODO: 실제 댓글 수로 교체
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.bookmark_border),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
