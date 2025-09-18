
import 'package:flutter/material.dart';
import 'package:pedal/widgets/card/reply_item.dart';

class CommentModal extends StatelessWidget {
  const CommentModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: Container(
          padding: const EdgeInsets.all(16.0), // Revert to static padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 3, // Dummy count
                  itemBuilder: (context, index) {
                    return const CommentItem();
                  },
                ),
              ),
              const Divider(color: Colors.grey, thickness: 0.5),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '댓글을 입력해주세요.',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        // Handle sending comment
                      },
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
  const CommentItem({super.key});

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
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seprogramd',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                        '와 엄청난데요? 저도 저렇게 라이딩 잘하고 싶습니다. 혹시 실례가 안된다면 같이 라이딩 가능하실까요...? 같이 해주신다면 정말 영광일 것 같습니다!!'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined, size: 16),
                        const SizedBox(width: 4),
                        const Text('1,234'),
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
                        _showReplies ? '댓글 숨기기' : '댓글 3개 더보기',
                        style: const TextStyle(color: Colors.blue),
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
