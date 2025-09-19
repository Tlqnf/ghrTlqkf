import 'package:flutter/material.dart';
import 'package:pedal/widgets/card/record_card.dart';
import 'package:pedal/screens/all_records_screen.dart';
import 'package:pedal/api/user_api_service.dart';
import 'package:pedal/models/user.dart';

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
            _RecordList(),
            const SizedBox(height: 16),
            _SectionHeader(title: '북마크 경로', showMoreButton: true),
            _RecordList(), // Reusing for bookmarked routes for now
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
                      backgroundImage: NetworkImage(_user!.profilePic),
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

class _RecordList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner ListView
      itemCount: 4, // Dummy count
      itemBuilder: (context, index) {
        return const RecordCard(
          routeName: '갤러리아 백화점 경로',
          distance: '17.28 km',
          time: '1시간 03분',
          date: '2025.09.01',
        );
      },
    );
  }
}
