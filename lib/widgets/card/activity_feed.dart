// lib/widgets/activity_feed.dart
import 'package:flutter/material.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/api/user_api_service.dart';
import 'activity_card.dart';

class ActivityFeed extends StatefulWidget {
  final String token;
  const ActivityFeed({super.key, required this.token});

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  final _scroll = ScrollController();
  final List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true; // 다음 페이지 존재 여부
  int _page = 1;        // 1부터 시작

  @override
  void initState() {
    super.initState();
    _loadNext(); // 첫 페이지 로드
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _isLoading || !_hasMore) return;
    const threshold = 300.0; // 끝에서 300px 남으면 다음 로드
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - threshold) {
      _loadNext();
    }
  }

  Future<void> _loadNext({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final nextPage = refresh ? 1 : _page;
      final fetched =
      await UserApiService.getRecentTenCard(widget.token, nextPage);

      setState(() {
        if (refresh) {
          _posts
            ..clear()
            ..addAll(fetched);
          _page = 2;
        } else {
          _posts.addAll(fetched);
          _page += 1;
        }
        _hasMore = fetched.length == 10; // 10개 미만이면 마지막 페이지로 판단
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('불러오기 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() => _loadNext(refresh: true);

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        itemCount: _posts.length + (_hasMore ? 1 : 0), // 바닥 로딩 인디케이터용
        itemBuilder: (context, index) {
          if (index < _posts.length) {
            final p = _posts[index];
            return ActivityCard(post: p, token: widget.token);
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
