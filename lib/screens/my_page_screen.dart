import 'package:flutter/material.dart';
import 'package:pedal/models/card.dart';
import 'package:pedal/widgets/card/record_card.dart';
import 'package:pedal/screens/all_records_screen.dart';
import 'package:pedal/api/user_api_service.dart';
import 'package:pedal/models/user.dart';
import 'package:intl/intl.dart';

class MyPageScreen extends StatefulWidget {
  final String token;
  const MyPageScreen({super.key, required this.token});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(token: widget.token), // Pass token to _ProfileHeader
            const SizedBox(height: 16),
            _SectionHeader(title: '내 기록', showMoreButton: true),
            _RecordListHeader(token: widget.token),
            const SizedBox(height: 16),
            _SectionHeader(title: '북마크 경로', showMoreButton: true),
            _RecordListBookHeader(token: widget.token),
            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final String token;
  const _ProfileHeader({required this.token});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await UserApiService.fetchUserProfile(widget.token);
      setState(() {
        _user = user;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _isLoading
              ? const CircleAvatar(
                  radius: 30,
                  child: CircularProgressIndicator(), // Loading indicator
                )
              : _user?.profilePic != null && _user!.profilePic.isNotEmpty
                  ? CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage('http://172.30.1.14:8080' + _user!.profilePic),
                    )
                  : const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/google.png'), // Fallback placeholder
                    ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoading
                    ? const Text(
                        'Loading...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    : Text(
                        _user?.username ?? 'Guest',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                _isLoading
                    ? const Text(
                        'Loading...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    : Text(
                        _user?.profileDescription ?? 'No description',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                if (_error != null)
                  Text(
                    'Error: $_error',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              UserApiService.logoutUserProfile(widget.token);
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}



class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showMoreButton;

  const _SectionHeader({
    required this.title,
    this.showMoreButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (showMoreButton)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AllRecordsScreen()));
              },
              child: const Text('더보기'),
            ),
        ],
      ),
    );
  }
}

class _RecordListHeader extends StatefulWidget {
  final String token;
  const _RecordListHeader({super.key, required this.token});

  @override
  State<_RecordListHeader> createState() => _RecordListHeaderState();
}

class _RecordListHeaderState extends State<_RecordListHeader> {
  String _formatDistance(double km) => '${km.toStringAsFixed(2)} km';

  String _formatTime(int h, int m) {
    if (h > 0) return '${h}시간 ${m.toString().padLeft(2, '0')}분';
    return '${m}분';
  }

  String _formatDate(String raw) {
    final parsed = DateTime.parse(raw).toLocal();
    return DateFormat('yyyy.MM.dd').format(parsed);
  }

  String _formatImage(String image) {
    final final_url = 'http://172.30.1.14:8080' + image;
    return final_url;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CardSummary>>(
      future: UserApiService.getRecentCard(widget.token), // ← 서버 호출
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('불러오기 실패: ${snap.error}'),
          );
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('최근 기록이 없습니다.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length, // ← 서버에서 온 개수만큼
          itemBuilder: (context, index) {
            final c = items[index];

            final distance = _formatDistance(c.distance);
            final time = _formatTime(c.time_hour, c.time_minute);
            final date     = _formatDate(c.created_at);
            final image_url = _formatImage(c.map_image_url);

            // ⚠️ const 제거! (실데이터 바인딩)
            return RecordCard(
              routeName: c.title,       // 서버의 title을 경로명으로 사용(필요시 변경)
              distance: distance,
              time: time,
              date: date,
              image_url: image_url,    // 위젯이 image_url(String) 받는다면 그대로
              // imageUrl로 받는 위젯이면 키 이름만 바꿔주면 됩니다.
            );
          },
        );
      },
    );
  }
}

class _RecordListBookHeader extends StatefulWidget {
  final String token;
  const _RecordListBookHeader({super.key, required this.token});

  @override
  State<_RecordListBookHeader> createState() => _RecordListBookHeaderState();
}

class _RecordListBookHeaderState extends State<_RecordListBookHeader> {
  String _formatDistance(double km) => '${km.toStringAsFixed(2)} km';

  String _formatTime(int h, int m) {
    if (h > 0) return '${h}시간 ${m.toString().padLeft(2, '0')}분';
    return '${m}분';
  }

  String _formatDate(String raw) {
    final parsed = DateTime.parse(raw).toLocal();
    return DateFormat('yyyy.MM.dd').format(parsed);
  }

  String _formatImage(String image) {
    final final_url = 'http://172.30.1.14:8080' + image;
    return final_url;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CardSummary>>(
      future: UserApiService.getRecentBookmarkCard(widget.token), // ← 서버 호출
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('불러오기 실패: ${snap.error}'),
          );
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('최근 기록이 없습니다.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length, // ← 서버에서 온 개수만큼
          itemBuilder: (context, index) {
            final c = items[index];

            final distance = _formatDistance(c.distance);
            final time = _formatTime(c.time_hour, c.time_minute);
            final date     = _formatDate(c.created_at);
            final image_url = _formatImage(c.map_image_url);

            // ⚠️ const 제거! (실데이터 바인딩)
            return RecordCard(
              routeName: c.title,       // 서버의 title을 경로명으로 사용(필요시 변경)
              distance: distance,
              time: time,
              date: date,
              image_url: image_url,    // 위젯이 image_url(String) 받는다면 그대로
              // imageUrl로 받는 위젯이면 키 이름만 바꿔주면 됩니다.
            );
          },
        );
      },
    );
  }
}
