import 'package:flutter/material.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/post_form_screen.dart';
import 'package:pedal/screens/report_detail_screen.dart';
import 'package:pedal/widgets/my/post_list.dart';
import 'package:provider/provider.dart';

class AllRecordsScreen extends StatefulWidget {
  final bool bookmarked;
  final String title;

  const AllRecordsScreen({
    super.key,
    required this.bookmarked,
    required this.title,
  });

  @override
  State<AllRecordsScreen> createState() => _AllRecordsScreenState();
}

class _AllRecordsScreenState extends State<AllRecordsScreen> {
  final List<Post> _records = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    _scrollController.addListener(() {
      if (!_isLoading &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          _hasMore) {
        _fetchRecords();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final List<Post> newRecords = widget.bookmarked
          ? await UserApi.getBookmarks(authProvider.token!, _page)
          : await UserApi.getPosts(authProvider.token!, _page);

      setState(() {
        if (newRecords.isNotEmpty) {
          _records.addAll(newRecords);
          _page++;
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Optional: Show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load records: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        flexibleSpace: Container(color: Theme.of(context).colorScheme.surface),
      ),
      body: _records.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Handle sorting by latest
                  },
                  child: const Text('최신순'),
                ),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                PostList(
                  bookmarked: widget.bookmarked,
                  postData: _records,
                  onItemTap: widget.bookmarked
                      ? null
                      : (Post post) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailScreen(
                          reportId: post.reportId,
                        ),
                      ),
                    );
                  },
                  onItemEdit: widget.bookmarked
                      ? null
                      : (Post post) {
                    // Only allow edit for non-bookmarked (my records)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostFormScreen(
                          postData: post,
                          routeId: post.routeId,
                          mapImagePath: post.mapImageUrl,
                        ),
                      ),
                    );
                  },
                ),
                if (_isLoading && _records.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}