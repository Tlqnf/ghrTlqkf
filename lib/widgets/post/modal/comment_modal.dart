import 'package:flutter/material.dart';
import 'package:pedal/api/comment_api.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/main.dart';
import 'package:pedal/models/comment.dart';
import 'package:pedal/models/user.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/widgets/post/card/reply_card.dart';
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
  bool _isMainInputFocused = false;

  late final String? token = context.read<AuthProvider>().token;
  Future<List<Comment>>? _commentsFuture;

  User? _user;

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_onFocusChange);
    _commentsFuture = CommentApi.getPostComments(token!, widget.postId);
    _fetchCurrentUser();
  }

  void _onFocusChange() {
    setState(() {
      _isMainInputFocused = _commentFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.removeListener(_onFocusChange);
    _commentFocusNode.dispose();
    super.dispose();
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
          parentId: null,
          postId: widget.postId,
        ),
      );
      _commentController.clear();
      await _fetchComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 등록되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 등록 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // 모달 드래그 핸들
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
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
                        );
                      },
                    );
                  }
                },
              ),
            ),
            // 댓글 입력창
            Padding(
              padding: EdgeInsets.only(
                bottom: _isMainInputFocused
                    ? MediaQuery.of(context).viewInsets.bottom
                    : 0,
              ),
              child: _buildCommentInput(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
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
                backgroundImage:
                AssetImage('assets/image/not_profile.png'),
              ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: const InputDecoration(
                hintText: '댓글을 입력해주세요.',
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
    );
  }
}

class CommentItem extends StatefulWidget {
  final dynamic comment;
  final VoidCallback onCommentMutated;

  const CommentItem(
      {super.key, required this.comment, required this.onCommentMutated});

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
    if (token != null) {
      _buildTextSpans(widget.comment.content);
    } else {
      _textSpans = [TextSpan(text: widget.comment.content)];
      _isBuildingText = false;
    }
  }

  Future<void> _buildTextSpans(String text) async {
    final List<TextSpan> spans = [];
    final RegExp mentionRegex = RegExp(r'@(\w+)');
    int lastMatchEnd = 0;

    for (final Match match in mentionRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final String username = match.group(1)!;
      final bool? isValid =
          token != null ? await UserApi.checkUserMention(username, token!) : null;

      if (isValid == true) {
        spans.add(TextSpan(
          text: match.group(0),
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ));
      } else {
        spans.add(TextSpan(text: match.group(0)));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    if (!mounted) return;
    setState(() {
      _textSpans = spans;
      _isBuildingText = false;
    });
  }

  void _initComment() async {
    if (token == null) return;
    try {
      final checked =
          await CommentApi.checkLikeComment(token!, widget.comment.commentId);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: $e')),
        );
      }
    }
  }

  void _handleReply() {
    if (token == null) return;
    final TextEditingController replyController = TextEditingController();
    final BuildContext originalContext = context;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                      backgroundImage:
                      AssetImage('assets/image/not_profile.png'),
                    ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: replyController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '대댓글을 입력해주세요.',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final content = replyController.text.trim();
                    if (content.isEmpty) return;

                    try {
                      await CommentApi.createComment(
                        token!,
                        CreateComment(
                          content: content,
                          parentId: widget.comment.commentId,
                          postId: widget.comment.postId,
                        ),
                      );
                      Navigator.pop(modalContext);
                      if (!mounted) return;
                      ScaffoldMessenger.of(originalContext).showSnackBar(
                        const SnackBar(content: Text('대댓글이 등록되었습니다.')),
                      );
                      widget.onCommentMutated();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(originalContext).showSnackBar(
                        SnackBar(content: Text('등록 실패: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDeleteModal() {
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
    final TextEditingController editController =
        TextEditingController(text: widget.comment.content);
    final BuildContext originalContext = context;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 8,
            right: 8,
            top: 8,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                      backgroundImage:
                      AssetImage('assets/image/not_profile.png'),
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
                          token!, widget.comment.commentId, newContent);
                      
                      Navigator.pop(modalContext);

                      if (!mounted) return;
                      ScaffoldMessenger.of(originalContext).showSnackBar(
                        const SnackBar(content: Text('댓글이 수정되었습니다.')),
                      );
                      widget.onCommentMutated();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(originalContext).showSnackBar(
                        SnackBar(content: Text('수정 실패: $e')),
                      );
                    }
                  },
                ),
              ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 삭제되었습니다.')),
      );
      widget.onCommentMutated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
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
                  backgroundImage: AssetImage('assets/image/not_profile.png'),
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
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            _isBuildingText
                                ? Text(widget.comment.content)
                                : RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: _textSpans ??
                                          [
                                            TextSpan(
                                                text: widget.comment.content)
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
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _likeCount.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                                  horizontal: 4, vertical: 2),
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