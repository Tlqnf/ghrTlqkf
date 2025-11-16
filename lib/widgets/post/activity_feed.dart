import 'package:flutter/material.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart';

import 'card/activity_card.dart';

class ActivityFeed extends StatefulWidget {
  final bool bookmarked;

  const ActivityFeed({super.key, required this.bookmarked});

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  final _scroll = ScrollController();
  final List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true; // 다음 페이지 존재 여부
  int _page = 1; // 1부터 시작

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadNext(); // 첫 페이지 로드
      }
    });
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    try {
      final nextPage = refresh ? 1 : _page;

      // `post_list.dart`의 로직에 따라, bookmarked 값으로 API를 선택합니다.
      // bookmarked: true => 사용자 게시물, false => 북마크 (post_list.dart 기준)
      // 북마크를 위한 페이지네이션 API로 `UserApi.getBookmarks`를 가정합니다.
      final fetched = widget.bookmarked
          ? await UserApi.getPosts(token, nextPage)
          : await UserApi.getBookmarks(token, nextPage);

      setState(() {
        if (refresh) {
          _posts
            ..clear()
            ..addAll(fetched as Iterable<Post>);
          _page = 2;
        } else {
          _posts.addAll(fetched as Iterable<Post>);
          _page += 1;
        }
        _hasMore = fetched.length == 10; // 10개 미만이면 마지막 페이지로 판단
      });
    } catch (e) {
      if (mounted) {
        showOverlaySnackBar(context, '불러오기 실패: $e');
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

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(child: Text('게시글이 없습니다.')),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        itemCount: _posts.length + (_hasMore ? 1 : 0), // 바닥 로딩 인디케이터용
        itemBuilder: (context, index) {
          if (index < _posts.length) {
            final p = _posts[index];
            return ActivityCard(post: p);
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
