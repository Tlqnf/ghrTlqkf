import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedal/api/post_api.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/models/user.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/post/full_screen_image.dart';
import 'package:pedal/widgets/post/modal/comment_modal.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:pedal/main.dart';

class ActivityCard extends StatefulWidget {
  final Post post;
  const ActivityCard({super.key, required this.post});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard>
    with AutomaticKeepAliveClientMixin {
  late final token = context.read<AuthProvider>().token;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isBookmark = false;
  bool _isMoreContent = false;
  bool _showRecordTab = false;
  int _currentImage = 0;

  User? _user; // null 허용

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _getUserInfo();
  }

  void _getUserInfo() async {
    try {
      final info = await UserApi.getUserById(token!, widget.post.userId);
      final checked = await PostApi.checkThumbsUp(token!, widget.post.id);
      final bookmarked = await PostApi.checkBookmark(token!, widget.post.id);
      if (mounted) {
        setState(() {
          _user = info;
          _isLiked = checked;
          _isBookmark = bookmarked;
        });
      }
    } catch (e) {
      debugPrint('유저 정보를 불러오는데 실패했습니다: $e');
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
      await PostApi.addThumbsUp(token, widget.post.id);
    } catch (e) {
      setState(() {
        _isLiked = prevLiked;
        _likeCount = prevCount;
      });
      if (mounted) {
        showOverlaySnackBar(context, '요청 실패: $e');
      }
    }
  }

  void _toggleBookmark(String token) async {
    setState(() {
      _isBookmark = !_isBookmark;
    });
    try {
      if (_isBookmark) {
        await PostApi.addBookmark(token, widget.post.id);
      } else {
        await PostApi.removeBookmark(token, widget.post.id);
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
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _recordTab() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border.all(width: 1, color: Colors.grey),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatColumn(
              '거리',
              '${(widget.post.distance).toStringAsFixed(2)} km',
            ),
            _buildStatColumn(
              '평균 속력',
              '${widget.post.speed.toStringAsFixed(2)} km/h',
            ),
            _buildStatColumn('총 시간', widget.post.time),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.post.images.length + 1, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentImage == index ? 10 : 8,
          height: _currentImage == index ? 10 : 8,
          decoration: BoxDecoration(
            color: _currentImage == index
                ? const Color(0xFFE74C3C)
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'yyyy.MM.dd a hh:mm',
      'ko_KR',
    ).format(widget.post.createdAt.toLocal());
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final postId = widget.post.id;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _user != null && _user!.profilePic!.isNotEmpty
                      ? CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white70,
                          backgroundImage: NetworkImage(_user!.profilePic!),
                        )
                      : const CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(
                            'assets/image/not_profile.png',
                          ),
                        ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.username ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showRecordTab = !_showRecordTab;
                      });
                    },
                    style: ButtonStyle(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.red[700]; // 눌렀을 때 색
                        }
                        return Colors.red; // 기본 색
                      }),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    child: Text(
                      _showRecordTab ? "기록 닫기" : "기록 열기",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 이미지 섹션
            SizedBox(
              height: MediaQuery.of(context).size.width,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: [
                  widget.post.images.isNotEmpty
                      ? PageView(
                          onPageChanged: (index) {
                            setState(() {
                              _currentImage = index;
                            });
                          },
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImage(
                                      imageUrl: widget.post.mapImageUrl,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(0),
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
                            ...widget.post.images.map(
                              (image) => GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImage(
                                        imageUrl: image["url"],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(0),
                                  child: Image.network(
                                    image["url"],
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Text('이미지를 불러올 수 없습니다.'),
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: Image.network(
                            widget.post.mapImageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Text('지도를 불러올 수 없습니다.')),
                          ),
                        ),
                  if (_showRecordTab)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: _recordTab(),
                    ),
                  if (widget.post.images.isNotEmpty)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: _buildIndicator(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 액션 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
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
                          builder: (context, scrollController) => DecoratedBox(
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
                        Icon(
                          Icons.chat_bubble_outline,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                    onPressed: () =>
                        token != null ? _toggleBookmark(token) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 해시 태그
            if (widget.post.hashTag.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 20.0,
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: widget.post.hashTag
                      .map(
                        (tag) => Text(
                          '#$tag',
                          style: TextStyle(
                            color: theme.extension<AppColors>()!.info,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // 게시물 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                widget.post.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // 게시물 내용
            _isMoreContent
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.content,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isMoreContent = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "간략히",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextButton(
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
                        style: TextStyle(fontSize: 16, color: Colors.grey),
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
