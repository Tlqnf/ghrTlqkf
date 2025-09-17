import 'package:flutter/material.dart';
import 'package:pedal/widgets/modal/comment_modal.dart';

class ActivityCard extends StatefulWidget {
  const ActivityCard({super.key});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isLiked = false;
  int _likeCount = 1234;

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.background, // 테마의 배경색 사용
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seprogramd',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '2025.09.10 오후 10:30',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '거리',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 4,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('17.32',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const SizedBox(width: 2),
                      const Text('km', style: TextStyle(color: Colors.black54, fontSize: 14)),
                    ]
                  )
                ],
              ),
              const SizedBox(width: 20,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '평균 속력',
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 4,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('19.92', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      const Text('km/h', style: TextStyle(color: Colors.black54, fontSize: 14)),
                    ]
                  )
                ],
              ),
              const SizedBox(width: 20,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '총 시간',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '3',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text('시간', style: TextStyle(color: Colors.black54, fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        '01',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text('분', style: TextStyle(color: Colors.black54, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Map Placeholder'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                      color: _isLiked ? Colors.blue : Colors.black54,
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
                    Text('12'),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.bookmark_border),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '#대전 #가오동_장동 #라이딩',
            style: TextStyle(color: Colors.blue),
          ),
          const SizedBox(height: 10),
          const Text('오늘 라이딩 완료'),
          const SizedBox(height: 20),
        ],
      )
    );
  }
}
