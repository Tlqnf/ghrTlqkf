import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:intl/intl.dart';
import 'package:pedal/api/route_api.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/providers/map_provider.dart';
import 'package:pedal/widgets/post/card/post_card.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart';
import 'package:provider/provider.dart';

class NavigationListModal extends StatefulWidget {
  final ScrollController scrollController;
  final MapProvider mapProvider;

  const NavigationListModal({
    super.key,
    required this.scrollController,
    required this.mapProvider
  });

  @override
  State<NavigationListModal> createState() => _NavigationListModalState();
}

class _NavigationListModalState extends State<NavigationListModal> {
  Future<Map<String, List<Post>>>? _routesFuture;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to access the provider safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null) {
        setState(() {
          _routesFuture = _fetchRoutes(authProvider.token!);
        });
      }
    });
  }

  Future<Map<String, List<Post>>> _fetchRoutes(String token) async {
    try {
      // Fetch both lists in parallel
      final results = await Future.wait([
        UserApi.getRecentPosts(token),
        UserApi.getRecentBookmarks(token),
      ]);
      return {
        'myRoutes': results[0],
        'bookmarkedRoutes': results[1],
      };
    } catch (e) {
      // Propagate error to be handled by FutureBuilder
      throw Exception('Failed to load routes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top grey handle bar
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 4,
                  width: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            FutureBuilder<Map<String, List<Post>>>(
              future: _routesFuture,
              builder: (context, snapshot) {
                if (_routesFuture == null) {
                  // This can happen if the token is not available initially
                  return const Center(child: Text('로그인이 필요합니다.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('경로를 불러오는데 실패했습니다.'));
                } else if (!snapshot.hasData ||
                    (snapshot.data!['myRoutes']!.isEmpty &&
                        snapshot.data!['bookmarkedRoutes']!.isEmpty)) {
                  return const Center(child: Text('표시할 경로가 없습니다.'));
                }

                final myRoutes = snapshot.data!['myRoutes']!;
                final bookmarkedRoutes = snapshot.data!['bookmarkedRoutes']!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (myRoutes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '내 경로',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildRouteList(myRoutes),
                      const SizedBox(height: 16),
                    ],
                    if (bookmarkedRoutes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '저장한 경로',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildRouteList(bookmarkedRoutes, isBookmark: true),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteList(List<Post> posts, {bool isBookmark = false}) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          routeName: isBookmark ? post.title : post.routeName,
          distance: '${post.distance.toStringAsFixed(2)} km',
          time: post.time,
          date: DateFormat('yyyy.MM.dd').format(post.createdAt),
          imageUrl: post.mapImageUrl,
          onTap: () async {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.token == null) return;

            try {
              final points = await RouteApi.getRoutePoint(post.routeId, authProvider.token!);
              final routeCoords = points.map((p) => NLatLng(p['lat'], p['lon'])).toList();
              if (routeCoords.isNotEmpty) {
                widget.mapProvider.startNavigation(routeCoords);
              } else {
                showOverlaySnackBar(context, '네비게이션 경로가 존재하지 않습니다.');
              }
            } catch (e) {
              showOverlaySnackBar(context, '경로를 불러오는데 실패했습니다: $e');
            }
          },
        );
      },
    );
  }
}