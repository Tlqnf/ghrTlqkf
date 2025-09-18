import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedal/services/ad_helper.dart';
import 'package:pedal/services/socket_service.dart';
import 'package:pedal/widgets/modal/record_list_modal.dart'; // Import RecordListModal

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  final MapController _mapController = MapController();

  final List<List<LatLng>> _routeChunks = [[]];
  final int _chunkSize = 5;

  late final SocketService _socketService;
  StreamSubscription<dynamic>? _socketStreamSubscription;

  // BannerAd? _bannerAd;

  // --- Map Interaction State ---
  bool _isFollowingUser = true;
  // ---------------------------

  @override
  void initState() {
    super.initState();
    _initializeLocationStream();
    _initializeSocket();
    // _createBannerAd();
  }

  // void _createBannerAd() {
  //   _bannerAd = BannerAd(
  //     size: AdSize.fullBanner,
  //     adUnitId: AdHelper.bannerAdUnitId!,
  //     listener: AdHelper.bannerAdListener,
  //     request: const AdRequest(),
  //   )..load();
  // }

  void _initializeSocket() {
    const socketUrl = 'ws://172.30.1.14:8080/ws/record-route';
    _socketService = SocketService(url: socketUrl);
    _socketService.connect();

    _socketStreamSubscription = _socketService.stream.listen((data) {
      if (mounted) {
        debugPrint("Received from socket: $data");
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map && decoded.containsKey('lat') && decoded.containsKey('lon')) {
            final calibratedPoint = LatLng(decoded['lat'], decoded['lon']);
            setState(() {
              _addPointToRoute(calibratedPoint);
            });
          }
        } catch (e) {
          debugPrint("Error processing socket message: $e");
        }
      }
    }, onError: (error) {
      debugPrint("Socket stream error: $error");
    });
  }

  void _addPointToRoute(LatLng point) {
    if (!mounted) return;
    setState(() {
      var lastChunk = _routeChunks.last;
      if (lastChunk.length >= _chunkSize) {
        _routeChunks.add([]);
        lastChunk = _routeChunks.last;
      }
      lastChunk.add(point);
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _socketStreamSubscription?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _initializeLocationStream() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied');
      return;
    }

    Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null && mounted) {
      final initialLocation = LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
      setState(() {
        _currentLocation = initialLocation;
        _isLoading = false;
      });
    }

    _startLocationStream();
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (mounted) {
          final newPoint = LatLng(position.latitude, position.longitude);
          setState(() {
            _currentLocation = newPoint;
            if (_isLoading) {
              _isLoading = false;
            }
          });

          if (_isFollowingUser) {
            _mapController.move(newPoint, _mapController.camera.zoom);
          }

          final locationData = {
            'lat': position.latitude,
            'lon': position.longitude,
          };
          _socketService.sendMessage(jsonEncode(locationData));
        }
      },
      onError: (error) {
        if (_isLoading) {
          _showError('Failed to get location: $error');
        }
      },
    );
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _recenterMap() {
    if (_currentLocation != null) {
      setState(() {
        _isFollowingUser = true;
      });
      _mapController.move(_currentLocation!, 16.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Polyline> polylines = _routeChunks
        .where((chunk) => chunk.isNotEmpty)
        .map((chunk) {
      return Polyline(
        points: chunk,
        strokeWidth: 4.0,
        color: Colors.blue,
      );
    }).toList();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null
              ? const Center(child: Text('위치 정보를 가져올 수 없습니다.'))
              : Stack(
                  children: [
                    // Map Layer
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation!,
                        initialZoom: 16.0,
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture && _isFollowingUser) {
                            setState(() {
                              _isFollowingUser = false;
                            });
                          }
                        },
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        PolylineLayer(polylines: polylines),
                        if (_currentLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentLocation!,
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40.0,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Top-left floating buttons
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      child: Column(
                        children: [
                          _buildFloatingButton(
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 32),
                          _buildFloatingButton(
                            icon: Icons.explore_outlined,
                            onPressed: () {
                              _mapController.rotate(0); // Reset map rotation to 0 degrees (north up)
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildFloatingButton(
                            icon: Icons.my_location,
                            onPressed: _recenterMap,
                          ),
                        ],
                      ),
                    ),

                    // AdMob Banner Placeholder at the bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          height: 60,
                          child: Center(
                            child: Text("placeholder"),
                          )// AdWidget(ad: _bannerAd!), // 배너 광고 추가
                        ),
                      ),
                    ),
                    // Slide-up bar for RecordListModal
                    Positioned(
                      bottom: 60, // Above the AdMob banner
                      left: 0,
                      right: 0,
                      child: SafeArea(
                          child: GestureDetector(
                            onVerticalDragEnd: (details) {
                              if (details.primaryVelocity! < 0) { // Check for upward drag
                                _showRecordListModal();
                              }
                            },
                            child: Container(
                              height: 30, // Height of the bar
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9), // Light background
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16.0),
                                  topRight: Radius.circular(16.0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, -2), // Shadow at the top
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      )
                    ),
                    // Floating Record Button above AdMob Banner
                    Positioned(
                      bottom: 100, // Adjust this value to position it correctly above the banner
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Implement start/stop recording logic
                            },
                            child: _buildRecordButton(),
                          ),
                        )
                      ),
                    ),
                    ],
                ),
      // Remove floatingActionButton and floatingActionButtonLocation from Scaffold
    );
  }

  void _showRecordListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final adBannerHeight = 60.0; // Height of the AdMob banner
        final availableHeight = screenHeight - adBannerHeight;
        final maxModalHeightFraction = availableHeight / screenHeight;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // Start at half screen height
          maxChildSize: maxModalHeightFraction, // Adjust max height to leave space for AdMob
          minChildSize: 0.4, // Can be dragged down to 20% of screen height
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white, // Background color of the modal
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: const RecordListModal(),
          ),
        );
      },
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildRecordButton() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
      ),
    );
  }
}