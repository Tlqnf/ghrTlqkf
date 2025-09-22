
import 'package:flutter/material.dart';
import 'package:pedal/api/comment_api.dart';
import 'package:pedal/models/comment.dart';
import 'package:pedal/widgets/card/reply_card.dart';

class CommentModal extends StatefulWidget {
  final String token;
  final int postId;
  const CommentModal({super.key, required this.token, required this.postId});

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  final TextEditingController _commentController = TextEditingController();

  // State for comments list
  List<CreateComment> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      // Optional: listen to text changes if needed
    });
    _fetchComments(); // Fetch comments when modal initializes
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Assuming getPostComments returns a List<Comment> or similar
      // For now, it returns void, so we'll simulate data or adjust API
      // dynamic fetchedData = await _commentApiService.getPostComments(widget.token, widget.postId);
      // _comments = fetchedData.map((json) => Comment.fromJson(json)).toList(); // Example mapping

      // Dummy data for now, as getPostComments returns void
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _comments = [
        CreateComment(content: '와 엄청난데요? 저도 저렇게 라이딩 잘하고 싶습니다. 혹시 실례가 안된다면 같이 라이딩 가능하실까요...? 같이 해주신다면 정말 영광일 것 같습니다!!', postId: widget.postId, mentions: []),
        CreateComment(content: '댓글 2', postId: widget.postId, mentions: []),
        CreateComment(content: '댓글 3', postId: widget.postId, mentions: []),
      ];

    } catch (e) {
      _errorMessage = '댓글을 불러오는데 실패했습니다: $e';
      debugPrint(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final commentContent = _commentController.text.trim();
    if (commentContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 내용을 입력해주세요.')),
      );
      return;
    }

    List<String> mentions = [];
    for (String a in commentContent.split(" ")) {
      if (a.startsWith("@")) {
        mentions.add(a.split("@").last);
      }
    }

    try {
      await CommentApiService.createComment(
        widget.token,
        CreateComment(
          content: commentContent,
          parentId: null, // Assuming top-level comment
          postId: widget.postId,
          mentions: mentions,
        ),
      );
      _commentController.clear(); // Clear text field
      await _fetchComments(); // Refresh comments list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 성공적으로 등록되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 등록 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : _comments.isEmpty
                            ? const Center(child: Text('아직 댓글이 없습니다.'))
                            : ListView.builder(
                                itemCount: _comments.length,
                                itemBuilder: (context, index) {
                                  final comment = _comments[index];
                                  return CommentItem(comment: comment); // Pass actual comment data
                                },
                              ),
              ),
              const Divider(thickness: 0.5),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration( // const for InputDecoration
                          hintText: '댓글을 입력해주세요.',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendComment, // Call the new send method
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommentItem extends StatefulWidget {
  final CreateComment comment; // Add comment data
  const CommentItem({super.key, required this.comment});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seprogramd', // 실제 사용자 이름으로 변경
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        widget.comment.content), // 실제 댓글 내용 표시
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined, size: 16),
                        const SizedBox(width: 4),
                        const Text('1,234'), // 실제 좋아요 수로 변경
                        const SizedBox(width: 16),
                        const Text('답글 달기'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // Remove padding
                        alignment: Alignment.centerLeft, // Align text to left
                        minimumSize: Size.zero, // Remove minimum size constraints
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrink tap target
                        overlayColor: Colors.transparent,
                      ),
                      onPressed: () {
                        setState(() {
                          _showReplies = !_showReplies;
                        });
                      },
                      child: Text(
                        _showReplies ? '댓글 숨기기' : '댓글 3개 더보기', // 실제 답글 수로 변경
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showReplies)
          Column(
            children: [
              ReplyItem(),
              ReplyItem(),
            ],
          ),
      ],
    );
  }
}
