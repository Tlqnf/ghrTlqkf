import 'package:flutter/material.dart';
import 'package:pedal/api/notice_api.dart';
import 'package:pedal/models/notice.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  Future<List<Notice>>? _noticesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_noticesFuture == null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        _noticesFuture = NoticeApi.getNotices(10, token);
      } else {
        _noticesFuture = Future.error('Not authenticated');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<List<Notice>>(
        future: _noticesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('공지사항이 없습니다.'));
          } else {
            final notices = snapshot.data!;
            return ListView.builder(
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                return ListTile(
                  title: Text(notice.title),
                  subtitle: Text(
                    notice.createdAt.split('T')[0], // Just show date
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        title: Text(notice.title),
                        content: SingleChildScrollView(
                          child: Text(notice.content)
                        ),
                        actions: [
                          TextButton(
                            child: const Text('닫기'),
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        ],
                      )
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}