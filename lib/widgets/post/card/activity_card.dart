import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedal/api/post_api.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/models/user.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/post/modal/comment_modal.dart';
import 'package:provider/provider.dart';
import 'package:pedal/main.dart';

class ActivityCard extends StatefulWidget {
  final Post post;
  const ActivityCard({super.key, required this.post});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard>
    with AutomaticKeepAliveClientMixin { // 🔹 상태 유지
  late final token = context.read<AuthProvider>().token;
  late bool _isLiked;
  late int _likeCount;
  late bool _isBookmark;
  bool _isMoreContent = false;

  User? _user; // null 허용
  bool _isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _isBookmark = false;
    _getUserInfo();
  }

  void _getUserInfo() async {
    try {
      final info = await UserApi.getUserById(token!, widget.post.userId);
      final checked = await PostApi.checkThumbsUp(token!, widget.post.id);
      if (mounted) {
        setState(() {
          _user = info;
          _isLoading = false;
          _isLiked = checked;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('유저 정보를 불러오는데 실패했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleLike(String token) async {
    final prevLiked = _isLiked;
    final prevCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await PostApi.addThumbsUp(token, widget.post.id);
      } else {
        await PostApi.removeThumbsUp(token, widget.post.id);
      }
    } catch (e) {
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

  void _toggleBookmark(String token) async {
    setState(() {
      _isBookmark = !_isBookmark;
    });
    try {
      if (_isBookmark) {
        await PostApi.removeBookmark(token, widget.post.id);
      } else {
        await PostApi.addBookmark(token, widget.post.id);
      }
    } catch (e) {
      setState(() {
        _isBookmark = !_isBookmark;
      });
    }
  }

  Widget _buildStatColumn(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.extension<AppColors>()!.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🔹 AutomaticKeepAliveClientMixin 적용 시 필요
    final theme = Theme.of(context);
    final formattedDate = DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR')
        .format(widget.post.createdAt.toLocal());
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final postId = widget.post.id;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                _user != null &&
                    _user!.profilePic != null &&
                    _user!.profilePic!.isNotEmpty
                    ? Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 37,
                    backgroundColor: Colors.transparent,
                    backgroundImage: NetworkImage(_user!.profilePic!),
                    child: _user!.profilePic == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                )
                    : const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent,
                  backgroundImage:
                  AssetImage('assets/image/not_profile.png'),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.username ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 24),

            // 통계 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildStatColumn(
                    '거리', '${widget.post.distance.toStringAsFixed(2)} km'),
                const SizedBox(width: 20),
                _buildStatColumn('평균 속력',
                    '${widget.post.speed.toStringAsFixed(2)} km/h'),
                const SizedBox(width: 20),
                _buildStatColumn('총 시간', widget.post.time),
              ],
            ),
            const SizedBox(height: 16),

            // 이미지 섹션
            SizedBox(
              height: 240,
              child: widget.post.images.isNotEmpty
                  ? PageView(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      widget.post.mapImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(
                        child: Text('지도를 불러올 수 없습니다.'),
                      ),
                    ),
                  ),
                  ...widget.post.images.map(
                        (imageUrl) => ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Center(
                          child: Text('이미지를 불러올 수 없습니다.'),
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  widget.post.mapImageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(
                    child: Text('지도를 불러올 수 없습니다.'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 액션 버튼
            Row(
              children: [
                InkWell(
                  onTap: () => token != null ? _toggleLike(token) : null,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        color: _isLiked
                            ? theme.extension<AppColors>()!.info
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _likeCount.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16.0),
                              topRight: Radius.circular(16.0),
                            ),
                          ),
                          child: CommentModal(postId: postId),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        widget.post.commentCount.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: _isBookmark
                      ? Icon(Icons.bookmark)
                      : Icon(Icons.bookmark_border),
                  color: _isBookmark
                      ? theme.extension<AppColors>()!.info
                      : theme.colorScheme.onSurfaceVariant,
                  onPressed: () => token != null ? _toggleBookmark(token) : null,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // 해시 태그
            if (widget.post.hashTag.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: widget.post.hashTag
                      .map((tag) => Text(
                    '#$tag',
                    style: TextStyle(
                      color: theme.extension<AppColors>()!.info,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ))
                      .toList(),
                ),
              ),

            // 게시물 제목
            Text(
              widget.post.title,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),

            // 게시물 내용
            _isMoreContent
                ? Text(
              widget.post.content,
              style: const TextStyle(fontSize: 16),
            )
                : TextButton(
              onPressed: () {
                setState(() {
                  _isMoreContent = true;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "더보기",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // 상태 유지
}
