import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedal/screens/post_form_screen.dart';
import 'package:pedal/services/socket_service.dart';
import 'package:pedal/widgets/map/pre_recording_overlay.dart';
import 'package:pedal/widgets/map/recording_overlay.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map and Location State
  NLatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  NaverMapController? _mapController;
  DateTime? _lastLocationUpdateTime;
  final List<List<NLatLng>> _routeChunks = [[]];
  final int _chunkSize = 5;
  bool _isFollowingUser = true;
  bool _isMapVisible = true;
  bool _isMapReady = false; // Variable to control map loading

  // Socket State
  late final SocketService _socketService;
  StreamSubscription<dynamic>? _socketStreamSubscription;
  bool _isSocketConnected = false;

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

    // Delay map loading to prevent transition animation conflicts
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _socketStreamSubscription?.cancel();
    _socketService.disconnect();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    const socketUrl =
        'ws://localhost:8080/ws/record-route?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc2MDc1NzQzfQ.F5ZrL5I4mCiYOml4I-v-9QyRF2nsDpMEYnGJdjRaG-k';
    _socketService = SocketService(url: socketUrl);

    _socketStreamSubscription = _socketService.stream.listen((data) {
      if (mounted && _isSocketConnected) {
        try {
          debugPrint('Socket received data: $data');
          final decoded = jsonDecode(data);
          if (decoded is Map &&
              decoded.containsKey('lat') &&
              decoded.containsKey('lon')) {
            final calibratedPoint = NLatLng(decoded['lat'], decoded['lon']);
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
      setState(() {
        _isSocketConnected = false;
      });
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
            NLatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
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
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
              (Position position) async {
            if (!mounted) return;

            // Throttle updates to once per second
            final now = DateTime.now();
            if (_lastLocationUpdateTime != null &&
                now.difference(_lastLocationUpdateTime!) <
                    const Duration(milliseconds: 500)) {
              return;
            }
            _lastLocationUpdateTime = now;

            final newPoint = NLatLng(position.latitude, position.longitude);
            final currentSpeedKmh = position.speed * 3.6;

            // Update marker on the map
            final marker = NMarker(
              id: 'current_location',
              position: newPoint,
              icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
              size: const Size(15, 15),
              anchor: const NPoint(0.5, 0.5),
            );
            _mapController?.addOverlay(marker);

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

              if (_isSocketConnected) {
                final locationData = {
                  'lat': position.latitude,
                  'lon': position.longitude,
                };
                final message = jsonEncode(locationData);
                _socketService.sendMessage(message);
                debugPrint('Socket sent data: $message');
              } else {
                // Offline mode: draw route directly from GPS
                _addPointToRoute(newPoint);
              }
            }

            setState(() {
              _currentLocation = newPoint;
              _currentSpeed = currentSpeedKmh;
              if (_isRecording && currentSpeedKmh > _maxSpeed) {
                _maxSpeed = currentSpeedKmh;
              }
              if (_isLoading) _isLoading = false;
            });

            // Update camera position if following user
            if (_isFollowingUser && _isMapVisible && _mapController != null) {
              final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
                target: newPoint,
                zoom: await _mapController!.getCameraPosition().then((p) => p.zoom),
              );
              _mapController!.updateCamera(cameraUpdate);
            }
          },
          onError: (error) {
            if (_isLoading) {
              _showError('Failed to get location: $error');
            }
          },
        );
  }

  void _addPointToRoute(NLatLng point) {
    if (!mounted) return;
    setState(() {
      var lastChunk = _routeChunks.last;
      if (lastChunk.length >= _chunkSize) {
        _routeChunks.add([]);
        lastChunk = _routeChunks.last;
      }
      lastChunk.add(point);

      // 지도 위에 경로 오버레이 갱신
      if (_mapController != null) {
        final chunkIndex = _routeChunks.length - 1;
        _mapController!.addOverlay(
          NPathOverlay(
            id: 'route_chunk_$chunkIndex',
            coords: lastChunk,
            width: 4,
            color: Colors.blue,
            outlineWidth: 1,
            outlineColor: Colors.white,
          ),
        );
      }
    });
  }

  void _startRecording() async {
    final bool connected = await _socketService.connect();
    setState(() {
      _isSocketConnected = connected;
    });

    if (!connected) {
      debugPrint('Socket connection failed. Starting in offline mode.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버에 연결할 수 없어 오프라인 모드로 주행을 기록합니다.')),
        );
      }
    } else {
      debugPrint('Socket connected for recording.');
    }

    _mapController?.clearOverlays();
    if (_currentLocation != null) {
      final marker = NMarker(
        id: 'current_location',
        position: _currentLocation!,
        icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
        size: const Size(15, 15),
        anchor: const NPoint(0.5, 0.5),
      );
      _mapController!.addOverlay(marker);
    }

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

  void _stopRecordingAndNavigate(BuildContext context) async {
    if (!_isRecording) return;
    _socketService.disconnect();
    debugPrint('Socket disconnected.');

    _isMapVisible = true;

    _stopwatch.stop();
    _timer?.cancel();

    final distanceInKm = (_distance / 1000).toStringAsFixed(2);
    final elapsedTime = _elapsedTime;
    final avgSpeed = _avgSpeed.toStringAsFixed(1);

    // --- Start: Snapshot Logic ---
    String? snapshotPath;
    final fullRoute = _routeChunks.expand((chunk) => chunk).toList();

    if (fullRoute.isNotEmpty && _mapController != null) {
      final bounds = NLatLngBounds.from(fullRoute);
      await _mapController!.updateCamera(
        NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(40)),
      );

      // Wait for the camera to move and the map to render before taking a snapshot.
    } else {
      await _mapController!.updateCamera(
        NCameraUpdate.withParams(target: _currentLocation),
      );
    }
    await Future.delayed(const Duration(milliseconds: 300));

    final imageFile = await _mapController!.takeSnapshot();
    snapshotPath = imageFile?.path;
    // --- End: Snapshot Logic ---

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PostFormScreen(
          initialDistance: distanceInKm,
          initialTime: elapsedTime,
          initialAvgSpeed: avgSpeed,
          mapImagePath: snapshotPath,
        ),
      ));
    }

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
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');
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
    if (_currentLocation != null && _mapController != null) {
      setState(() {
        _isFollowingUser = true;
      });
      _mapController!.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: _currentLocation!,
          zoom: 16.5,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null
          ? const Center(child: Text('위치 정보를 가져올 수 없습니다.'))
          : Stack(
        children: [
          Offstage(
            offstage: !_isMapVisible || !_isMapReady,
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: _currentLocation!,
                  zoom: 16.0,
                ),
                locationButtonEnable: false,
                consumeSymbolTapEvents: false,
                mapType: NMapType.basic,
                buildingHeight: 0.0,
                indoorEnable: false,
                liteModeEnable: true,
                symbolScale: 0.0,
                nightModeEnable: false,
              ),
              onMapReady: (controller) async {
                _mapController = controller;

                if (_currentLocation != null) {
                  // Add the initial location marker when the map is ready
                  final marker = NMarker(
                    id: 'current_location',
                    position: _currentLocation!,
                    icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
                    size: const Size(15, 15),
                    anchor: const NPoint(0.5, 0.5),
                  );
                  _mapController!.addOverlay(marker);
                }
              },
              onCameraChange:
                  (NCameraUpdateReason reason, bool animated) {
                if (reason == NCameraUpdateReason.gesture &&
                    _isFollowingUser) {
                  setState(() {
                    _isFollowingUser = false;
                  });
                }
              },
            ),
          ),
          if (!_isMapVisible && _isMapReady)
            Container(color: Colors.white),

          // Conditional Overlays
          _isRecording
              ? RecordingOverlay(
            isPaused: _isPaused,
            isMapVisible: _isMapVisible,
            distance: _distance,
            avgSpeed: _avgSpeed,
            elapsedTime: _elapsedTime,
            currentSpeed: _currentSpeed,
            maxSpeed: _maxSpeed,
            onRotateMap: () => _mapController?.updateCamera(
                NCameraUpdate.withParams(bearing: 0)),
            onRecenterMap: _recenterMap,
            onTogglePause: _togglePause,
            onStopRecording: () =>
                _stopRecordingAndNavigate(context),
            onToggleMapVisibility: () {
              setState(() {
                _isMapVisible = !_isMapVisible;
              });
            },
            mapController: _mapController,
          )
              : PreRecordingOverlay(
            onBackPressed: () =>
                Navigator.of(context).pop(),
            onRotateMap: () => _mapController?.updateCamera(
                NCameraUpdate.withParams(bearing: 0)),
            onRecenterMap: _recenterMap,
            onStartRecording: _startRecording,
            mapController: _mapController,
          ),

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
}