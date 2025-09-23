import 'package:flutter/material.dart';
import 'package:pedal/api/comment_api.dart';
import 'package:pedal/models/comment.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pedal/api/user_api.dart';

class ReplyArea extends StatefulWidget {
  final int commentId;
  const ReplyArea({super.key, required this.commentId});

  @override
  State<ReplyArea> createState() => _ReplyAreaState();
}

class _ReplyAreaState extends State<ReplyArea> {
  late final String? token;
  bool _showReplies = false;

  List<Reply>? _replies;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    token = context.read<AuthProvider>().token;
    debugPrint('initState - token: $token'); // token 확인
    _getReplies();
  }

  Future<void> _getReplies() async {
    debugPrint('_getReplies 호출');

    if (token == null) {
      debugPrint('_getReplies - token null!');
      setState(() {
        _errorMessage = '로그인이 필요합니다.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final replies =
      await CommentApi.getCommentReplies(widget.commentId, token!);
      debugPrint('_getReplies - replies: $replies'); // API 결과 확인

      if (!mounted) return;
      setState(() {
        _replies = replies;
        debugPrint('_getReplies - _replies length: ${_replies?.length}');
      });
    } catch (e) {
      debugPrint('_getReplies - 에러 발생: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = '대댓글을 불러오는데 실패했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          debugPrint('_getReplies - 로딩 종료');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build 호출 - _replies: $_replies, _isLoading: $_isLoading, _errorMessage: $_errorMessage');

    // 로딩 중
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(left: 40.0, top: 8.0, bottom: 8.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // 에러 발생
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 40.0, top: 8.0, bottom: 8.0),
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    // 대댓글이 없을 경우
    if (_replies == null || _replies!.isEmpty) {
      debugPrint('build - 대댓글 없음');
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "댓글 N개 더보기" 버튼
        Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              overlayColor: Colors.transparent,
            ),
            onPressed: () {
              setState(() {
                _showReplies = !_showReplies;
                debugPrint('build - _showReplies: $_showReplies');
              });
            },
            child: Text(
              _showReplies
                  ? '댓글 숨기기'
                  : '댓글 ${_replies!.length}개 더보기',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),

        // ReplyItem 리스트
        if (_showReplies)
          Column(
            children: _replies!
                .map((reply) {
              debugPrint('build - ReplyItem 생성: $reply');
              return ReplyItem(reply: reply, parentId: widget.commentId);
            }).toList(),
          ),
      ],
    );
  }
}

class ReplyItem extends StatefulWidget {
  final Reply reply;
  final int parentId;

  const ReplyItem({super.key, required this.reply, required this.parentId});

  @override
  State<ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<ReplyItem> {
  late final token = context.read<AuthProvider>().token;
  late int likeCount;
  late bool _isLiked = false;
  bool isLoading = false; // 로딩 상태 추가
  Future<List<TextSpan>>? _textSpansFuture;

  @override
  void initState() {
    super.initState();
    likeCount = widget.reply.likeCount!;
    _getLiked();
    if (token != null) {
      _textSpansFuture = _buildTextSpans(widget.reply.content!);
    }
  }

  Future<List<TextSpan>> _buildTextSpans(String text) async {
    final List<TextSpan> spans = [];
    if (token == null) {
      spans.add(TextSpan(text: text));
      return spans;
    }

    final RegExp mentionRegex = RegExp(r'@(\w+)');
    int lastMatchEnd = 0;

    for (final Match match in mentionRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final String username = match.group(1)!;
      final bool? isValid = await UserApi.checkUserMention(username, token!);

      if (isValid == true) {
        spans.add(TextSpan(
          text: match.group(0),
          style: const TextStyle(
              color: Colors.blue, fontWeight: FontWeight.bold),
        ));
      } else {
        spans.add(TextSpan(text: match.group(0)));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  void _getLiked() async {
    setState(() {
      isLoading = true;
    });
    final checked = await CommentApi.checkLikeComment(token!, widget.reply.id!);
    setState(() {
      _isLiked = checked;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, top: 12.0, bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onLongPress: _showEditDeleteModal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.reply.username!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<List<TextSpan>>(
                    future: _textSpansFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: snapshot.data,
                          ),
                        );
                      }
                      return Text(widget.reply.content!);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: isLoading ? null : _handleLike, // 로딩 중이면 클릭 비활성화
                        child: Icon(
                          _isLiked
                              ? Icons.thumb_up_alt
                              : Icons.thumb_up_alt_outlined,
                          size: 14,
                          color: _isLiked ? Colors.blue : null,
                        ),
                      ),
                      const SizedBox(width: 4),
                      isLoading
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(likeCount.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLike() async {
    setState(() {
      isLoading = true;
    });
    await CommentApi.likeComment(token!, widget.reply.id!);
    setState(() {
      _isLiked = !_isLiked;
      likeCount += _isLiked ? 1 : -1;
      isLoading = false;
    });
  }

  void _showEditDeleteModal() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
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
    );
  }

  void _handleEdit() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: const Text('댓글 수정 UI'),
      ),
    );
  }

  void _handleDelete() async {
    setState(() {
      isLoading = true;
    });
    await CommentApi.deleteComment(token!, widget.reply.id!);
    setState(() {
      isLoading = false;
    });
    // 필요 시 삭제 후 UI 업데이트 콜백 추가 가능
  }
}
