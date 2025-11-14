import 'package:flutter/material.dart';
import 'package:pedal/api/comment_api.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/main.dart';
import 'package:pedal/models/comment.dart';
import 'package:pedal/models/user.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/utils/comment_mention.dart';
import 'package:pedal/widgets/post/card/reply_card.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart';
import 'package:provider/provider.dart';

class CommentModal extends StatefulWidget {
  final int postId;
  const CommentModal({super.key, required this.postId});

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  late final String? token = context.read<AuthProvider>().token;
  Future<List<Comment>>? _commentsFuture;

  User? _user;

  int? _replyingToCommentId;
  String? _replyingToUsername;
  bool get _isReplying => _replyingToCommentId != null;

  @override
  void initState() {
    super.initState();
    _commentsFuture = CommentApi.getPostComments(token!, widget.postId);
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void startReplying(int commentId, String username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
      _commentController.text = '@$username ';
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
      _commentFocusNode.requestFocus();
    });
  }

  void cancelReplying() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
      _commentController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _fetchCurrentUser() async {
    if (token == null) return;
    try {
      final userInfo = await UserApi.fetchUserProfile(token!);
      if (!mounted) return;
      setState(() {
        _user = userInfo;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchComments() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _commentsFuture = CommentApi.getPostComments(token!, widget.postId);
    });
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      await CommentApi.createComment(
        token!,
        CreateComment(
          content: content,
          parentId: _replyingToCommentId,
          postId: widget.postId,
        ),
      );
      _commentController.clear();
      await _fetchComments();
      if (mounted) {
        showOverlaySnackBar(
          context,
          _isReplying ? '대댓글이 등록되었습니다.' : '댓글이 등록되었습니다.',
        );
      }
      if (_isReplying) {
        cancelReplying();
      }
    } catch (e) {
      if (mounted) {
        showOverlaySnackBar(context, '등록 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // 모달 드래그 핸들
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
              child: SizedBox(
                width: 40,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // 댓글 목록
            Expanded(
              child: FutureBuilder<List<Comment>>(
                future: _commentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('아직 댓글이 없습니다.'));
                  } else {
                    final comments = snapshot.data!;
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return CommentItem(
                          comment: comments[index],
                          onCommentMutated: _fetchComments,
                          onStartReply: startReplying,
                          currentUser: _user,
                        );
                      },
                    );
                  }
                },
              ),
            ),
            // 댓글 입력창
            Padding(
              padding: EdgeInsets.only(),
              child: _buildCommentInput(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isReplying)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  Text(
                    '$_replyingToUsername 님에게 답글 남기는 중',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: cancelReplying,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _user != null &&
                        _user!.profilePic != null &&
                        _user!.profilePic!.isNotEmpty
                    ? CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(_user!.profilePic!),
                      )
                    : const CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage(
                          'assets/image/not_profile.png',
                        ),
                      ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: _isReplying ? '대댓글을 입력해주세요.' : '댓글을 입력해주세요.',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentItem extends StatefulWidget {
  final dynamic comment;
  final VoidCallback onCommentMutated;
  final Function(int commentId, String username) onStartReply;
  final User? currentUser;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onCommentMutated,
    required this.onStartReply,
    this.currentUser,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  User? _user;
  late final String? token = context.read<AuthProvider>().token;
  late int _likeCount;
  bool _isLiked = false;

  // FutureBuilder 없애고 상태 변수로 변경
  List<TextSpan>? _textSpans;
  bool _isBuildingText = true;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.comment.likeCount ?? 0;
    _initComment();
    _getUser();
    _buildSpans();
  }

  void _buildSpans() async {
    if (!mounted) return;

    setState(() {
      _isBuildingText = true;
    });

    try {
      final spans = await buildMentionTextSpans(widget.comment.content, token);
      if (mounted) {
        setState(() {
          _textSpans = spans;
          _isBuildingText = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _textSpans = [TextSpan(text: widget.comment.content)];
          _isBuildingText = false;
        });
      }
    }
  }

  void _initComment() async {
    if (token == null) return;
    try {
      final checked = await CommentApi.checkLikeComment(
        token!,
        widget.comment.commentId,
      );
      if (!mounted) return;
      setState(() {
        _isLiked = checked;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  void _getUser() async {
    if (token == null) return;
    try {
      final info = await UserApi.getUserById(token!, widget.comment.userId);
      if (!mounted) return;
      setState(() {
        _user = info;
      });
    } catch (e) {
      debugPrint("유저 오류 발생: $e");
    }
  }

  void _toggleLike() async {
    if (token == null) return;

    final prevLiked = _isLiked;
    final prevCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await CommentApi.likeComment(token!, widget.comment.commentId);
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

  void _handleReply() {
    widget.onStartReply(
      widget.comment.commentId,
      _user?.username ?? '알 수 없는 사용자',
    );
  }

  void _showEditDeleteModal() {
    final isAuthor = widget.currentUser?.id == widget.comment.userId;
    if (!isAuthor) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                _handleEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('삭제'),
              onTap: () {
                Navigator.pop(context);
                _handleDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleEdit() {
    if (token == null) return;
    final TextEditingController editController = TextEditingController(
      text: widget.comment.content,
    );
    final BuildContext originalContext = context;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 8,
            right: 8,
            top: 8,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ColoredBox(
              color: Theme.of(modalContext).scaffoldBackgroundColor,
              child: Row(
                children: [
                  _user != null &&
                          _user!.profilePic != null &&
                          _user!.profilePic!.isNotEmpty
                      ? CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(_user!.profilePic!),
                        )
                      : const CircleAvatar(
                          radius: 18,
                          backgroundImage: AssetImage(
                            'assets/image/not_profile.png',
                          ),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: editController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '수정할 댓글을 입력해주세요.',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final newContent = editController.text.trim();
                      if (newContent.isEmpty) return;

                      try {
                        await CommentApi.updateComment(
                          token!,
                          widget.comment.commentId,
                          newContent,
                        );

                        Navigator.pop(modalContext);

                        showOverlaySnackBar(originalContext, '댓글이 수정되었습니다.');
                        widget.onCommentMutated();
                      } catch (e) {
                        showOverlaySnackBar(originalContext, '수정 실패: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDelete() async {
    if (token == null) return;
    try {
      await CommentApi.deleteComment(token!, widget.comment.commentId);
      if (!mounted) return;
      showOverlaySnackBar(context, '댓글이 삭제되었습니다.');
      widget.onCommentMutated();
    } catch (e) {
      if (!mounted) return;
      showOverlaySnackBar(context, '삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필
                _user != null &&
                        _user!.profilePic != null &&
                        _user!.profilePic!.isNotEmpty
                    ? CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(_user!.profilePic!),
                      )
                    : const CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage(
                          'assets/image/not_profile.png',
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 댓글 내용 영역만 LongPress 적용
                      GestureDetector(
                        onLongPress: _showEditDeleteModal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user?.username ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isBuildingText
                                ? Text(widget.comment.content)
                                : RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children:
                                          _textSpans ??
                                          [
                                            TextSpan(
                                              text: widget.comment.content,
                                            ),
                                          ],
                                    ),
                                  ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // 좋아요 버튼
                          InkWell(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  _isLiked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_alt_outlined,
                                  color: _isLiked
                                      ? AppColors.light.info!
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _likeCount.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 답글 버튼
                          InkWell(
                            onTap: _handleReply,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text('답글 달기'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 대댓글 영역 - LongPress 영향 없음
            ReplyArea(commentId: widget.comment.commentId),
          ],
        ),
      ),
    );
  }
}
