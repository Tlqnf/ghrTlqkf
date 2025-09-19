import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedal/screens/post_form_screen.dart';
import 'package:pedal/services/socket_service.dart';
import 'package:pedal/widgets/modal/navigation_list_modal.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map and Location State
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  final MapController _mapController = MapController();
  final List<List<LatLng>> _routeChunks = [[]];
  final int _chunkSize = 5;
  bool _isFollowingUser = true;
  bool _isMapVisible = true;

  // Socket State
  late final SocketService _socketService;
  StreamSubscription<dynamic>? _socketStreamSubscription;

  // Recording State
  bool _isRecording = false;
  bool _isPaused = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  double _distance = 0.0; // in meters
  double _avgSpeed = 0.0; // in km/h
  double _currentSpeed = 0.0; // in km/h
  double _maxSpeed = 0.0; // in km/h

  @override
  void initState() {
    super.initState();
    _initializeLocationStream();
    _initializeSocket();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _socketStreamSubscription?.cancel();
    _socketService.disconnect();
    _timer?.cancel();
    super.dispose();
  }

  void _initializeSocket() {
    const socketUrl = 'ws://172.30.1.14:8080/ws/record-route';
    _socketService = SocketService(url: socketUrl);
    _socketService.connect();

    _socketStreamSubscription = _socketService.stream.listen((data) {
      if (mounted) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map &&
              decoded.containsKey('lat') &&
              decoded.containsKey('lon')) {
            final calibratedPoint = LatLng(decoded['lat'], decoded['lon']);
            if (_isRecording && !_isPaused) {
              _addPointToRoute(calibratedPoint);
            }
          }
        } catch (e) {
          debugPrint("Error processing socket message: $e");
        }
      }
    }, onError: (error) {
      debugPrint("Socket stream error: $error");
    });
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
      setState(() {
        _currentLocation =
            LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
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

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(
      (Position position) {
        if (mounted) {
          final newPoint = LatLng(position.latitude, position.longitude);
          final currentSpeedKmh = position.speed * 3.6;

          if (_isRecording && !_isPaused) {
            final lastPoint = _currentLocation;
            if (lastPoint != null) {
              _distance += Geolocator.distanceBetween(
                lastPoint.latitude,
                lastPoint.longitude,
                newPoint.latitude,
                newPoint.longitude,
              );
            }
            if (_stopwatch.elapsed.inSeconds > 0) {
              _avgSpeed = (_distance / _stopwatch.elapsed.inSeconds) * 3.6;
            }
            final locationData = {
              'lat': position.latitude,
              'lon': position.longitude,
            };
            _socketService.sendMessage(jsonEncode(locationData));
          }

          setState(() {
            _currentLocation = newPoint;
            _currentSpeed = currentSpeedKmh;
            if (_isRecording && currentSpeedKmh > _maxSpeed) {
              _maxSpeed = currentSpeedKmh;
            }
            if (_isLoading) _isLoading = false;
          });

          if (_isFollowingUser && _isMapVisible) {
            _mapController.move(newPoint, _mapController.camera.zoom);
          }
        }
      },
      onError: (error) {
        if (_isLoading) {
          _showError('Failed to get location: $error');
        }
      },
    );
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

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;

      // Reset values
      _distance = 0.0;
      _avgSpeed = 0.0;
      _elapsedTime = '00:00:00';
      _currentSpeed = 0.0;
      _maxSpeed = 0.0;
      _routeChunks.clear();
      _routeChunks.add([]);

      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsedTime = _formatTime(_stopwatch.elapsed.inSeconds);
          });
        }
      });
    });
  }

  void _stopRecordingAndNavigate(BuildContext context) {
    if (!_isRecording) return;
    _isMapVisible = true;

    _stopwatch.stop();
    _timer?.cancel();

    final distanceInKm = (_distance / 1000).toStringAsFixed(2);
    final elapsedTime = _elapsedTime;
    final avgSpeed = _avgSpeed.toStringAsFixed(1);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PostFormScreen(
        initialDistance: distanceInKm,
        initialTime: elapsedTime,
        initialAvgSpeed: avgSpeed,
      ),
    ));

    setState(() {
      _isRecording = false;
      _isPaused = false;

      _stopwatch.reset();
      _distance = 0.0;
      _avgSpeed = 0.0;
      _elapsedTime = '00:00:00';
      _currentSpeed = 0.0;
      _maxSpeed = 0.0;
      _routeChunks.clear();
      _routeChunks.add([]);
    });
  }

  void _togglePause() {
    if (!_isRecording) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
        .map((chunk) => Polyline(
              points: chunk,
              strokeWidth: 4.0,
              color: Colors.blue,
            ))
        .toList();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null
              ? const Center(child: Text('위치 정보를 가져올 수 없습니다.'))
              : Stack(
                  children: [
                    // FlutterMap or placeholder
                    if (_isMapVisible)
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
                            flags: InteractiveFlag.pinchZoom |
                                InteractiveFlag.drag |
                                InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
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
                      )
                    else
                      Container(color: Colors.white), // Placeholder for no-map view

                    // Conditional Overlays
                    ..._isRecording
                        ? _buildRecordingOverlay(context)
                        : _buildPreRecordingOverlay(context),

                    // Common UI - Ad Banner
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          height: 60,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Text(
                              'Ad Placeholder',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // --- UI Builder Methods ---
  List<Widget> _buildPreRecordingOverlay(BuildContext context) {
    return [
      Positioned(
        top: MediaQuery.of(context).padding.top + 20,
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
              onPressed: () => _mapController.rotate(0),
            ),
            const SizedBox(height: 8),
            _buildFloatingButton(
              icon: Icons.my_location,
              onPressed: _recenterMap,
            ),
          ],
        ),
      ),
      Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: _startRecording,
            child: _buildRecordButton(),
          ),
        ),
      ),
      Positioned(
        // 모달
        left: 0,
        right: 0,
        bottom: 60, // Above the ad banner
        top: 0, // Allow it to go all the way to the top
        child: DraggableScrollableSheet(
          initialChildSize: 80 / (MediaQuery.of(context).size.height - 60),
          minChildSize: 80 / (MediaQuery.of(context).size.height - 60),
          maxChildSize: 600 / (MediaQuery.of(context).size.height - 60),
          builder: (BuildContext context, ScrollController scrollController) {
            return NavigationListModal(scrollController: scrollController);
          },
        ),
      ),
    ];
  }

  List<Widget> _buildRecordingOverlay(BuildContext context) {
    return [
      // === Top section: Either map stats or no-map view ===
      if (_isMapVisible) ...[
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('거리', (_distance / 1000).toStringAsFixed(2), 'km'),
              _buildStatCard('평균 속력', _avgSpeed.toStringAsFixed(1), 'km/h'),
              _buildStatCard('시간', _elapsedTime, ''),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 100,
          left: 16,
          child: Column(
            children: [
              _buildFloatingButton(
                icon: Icons.explore_outlined,
                onPressed: () => _mapController.rotate(0),
              ),
              const SizedBox(height: 8),
              _buildFloatingButton(
                icon: Icons.my_location,
                onPressed: _recenterMap,
              ),
            ],
          ),
        ),
      ] else ...[
        // This is the new UI based on the image
        Positioned.fill(
          child: _buildNoMapRecordingView(),
        ),
      ],

      // === Bottom section: Common controls ===
      Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause,
                          size: 50),
                      onPressed: _togglePause,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.stop, size: 50),
                      onPressed: () =>
                          _stopRecordingAndNavigate(context), // Stop recording
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildFloatingButton(
                icon: _isMapVisible ? Icons.layers_clear : Icons.layers,
                onPressed: () {
                  setState(() {
                    _isMapVisible = !_isMapVisible;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildNoMapRecordingView() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 180), // Bottom padding for controls
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          const Text('현재 속력', style: TextStyle(fontSize: 20, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            _currentSpeed.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 96,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _togglePause,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              _isPaused ? '라이딩 재개' : '라이딩 일시정지',
              style: const TextStyle(color: Colors.orange, fontSize: 16),
            ),
          ),
          const SizedBox(height: 60),
          _buildNoMapStatRow('거리(km)', (_distance / 1000).toStringAsFixed(2),
              '시간', _elapsedTime),
          const SizedBox(height: 30),
          _buildNoMapStatRow('평균 속력', _avgSpeed.toStringAsFixed(1), '최고 속도',
              _maxSpeed.toStringAsFixed(1)),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildNoMapStatRow(
      String title1, String value1, String title2, String value2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(child: _buildNoMapStat(title1, value1)),
        const SizedBox(width: 20),
        Expanded(child: _buildNoMapStat(title2, value2)),
      ],
    );
  }

  Widget _buildNoMapStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 36,
              color: Color(0xFF007AFF),
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFloatingButton(
      {required IconData icon, required VoidCallback onPressed}) {
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
        icon: Icon(icon, color: Colors.black87, size: 28),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildRecordButton() {
    return SafeArea(
      child: Container(
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
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007AFF))),
              // if (unit.isNotEmpty) const SizedBox(width: 4),
              if (unit.isNotEmpty)
                Text(unit,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }
}
